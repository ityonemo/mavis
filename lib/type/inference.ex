defmodule Type.Inference.Macros do
  defmacro opcode(op_ast, state_ast, do: block) do
    quote do
      def do_infer(unquote(state_ast) = %{code: [op = unquote(op_ast) | rest]}) do
        unquote(state_ast) |> IO.inspect(label: "5")
        new_state = unquote(block)
        |> IO.inspect(label: "7")

        if length(new_state.regs) != length(unquote(state_ast).regs) + 1 do
          raise "this opcode must append to the registers"
        end

        %{new_state |
          code: rest,
          stack: [op | unquote(state_ast).stack]}
      end
    end
  end

  defmacro opcode(operand) do
    quote do
      def do_infer(state = %{code: [op | rest]}) when op == unquote(operand) or (elem(op, 0) == unquote(operand)) do
        repeat(%{state |
          code: rest,
          stack: [op | state.stack]})
      end
    end
  end
end

defmodule Type.Inference do

  import Type, only: [builtin: 1]
  require Type.Inference.Macros
  import Type.Inference.Macros

  @enforce_keys [:code, :regs]
  defstruct @enforce_keys ++ [
    stack: [],
    meta:  %{line: nil, label: nil}
  ]

  @type opcode :: atom | tuple
  @type metadata :: %{line: nil | integer, label: nil | integer}
  @type reg_state :: %{optional(integer) => Type.t}

  @type state :: %__MODULE__{
    code:  [opcode],
    stack: [opcode],
    regs:  [[reg_state]],
    meta:  metadata
  }

  def run(code, starting_map) do
    [end_states | rest] = do_analyze(%__MODULE__{code: code, regs: [[starting_map]]})

    type = rest
    |> List.last   # grab the end states
    |> Enum.zip(end_states)
    |> Enum.map(fn {params, return} ->
      %Type.Function{params: Map.values(params), return: return[0]}
    end)
    |> Enum.into(%Type.Union{})

    {:ok, type}
  end

  def do_analyze(%{code: [], regs: registers}), do: registers
  def do_analyze(state) do
    state
    |> do_infer
    |> do_analyze
  end

  opcode {:move, from, {:x, to}}, state do
    put_reg(state, to, type_of(state, from))
  end

  opcode {:line, n}, state do
    state
    |> put_meta(:line, n)
    |> repeat
  end

  opcode {:label, n}, state do
    state
    |> put_meta(:label, n)
    |> repeat
  end

  opcode :func_info
  opcode :test_heap
  opcode :return

  def do_infer(opcode, _, _) do
    raise "unknown opcode #{inspect opcode}"
  end

  # helpers
  defp put_reg(state, reg, values = [_ | _]) do
    new_regs = state.regs
    |> hd
    |> Enum.zip(values)
    |> Enum.map(fn {map, value} -> Map.put(map, reg, value) end)

    %{state | regs: [new_regs | state.regs]}
  end
  defp put_reg(state, reg, value) do
    new_regs = state.regs
    |> hd
    |> Enum.map(&Map.put(&1, reg, value))

    %{state | regs: [new_regs | state.regs]}
  end
  defp put_meta(state, tag, value) do
    %{state | meta: Map.put(state.meta, tag, value)}
  end

  defp type_of(state, {:x, reg}) do
    state.regs
    |> hd
    |> Enum.map(&Map.get(&1, reg))
  end
  defp type_of(_state, {lit, value}) when lit in [:integer, :atom], do: value
  defp type_of(_state, {:literal, value}) do
    Type.of(value)
  end

  defp repeat(state = %{regs: regs}) do
    %{state | regs: [hd(regs) | regs]}
  end

  defp idem(typestate = [head | _]), do: [head | typestate]
end
