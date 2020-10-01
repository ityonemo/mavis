defmodule Type.Inference.Macros do
  defp strip({:{}, _, tup_list}), do: List.first(tup_list)
  defp strip(tup) when is_tuple(tup), do: elem(tup, 0)

  defmacro opcode(op_ast, state_ast, do: block) do
    opcode_name = strip(op_ast)
    quote do
      def do_infer(unquote(state_ast) = %{code: [op = unquote(op_ast) | rest]}) do
        unquote(state_ast)
        new_state = unquote(block)

        if length(new_state.regs) != length(unquote(state_ast).regs) + 1 do
          raise "the opcode #{unquote opcode_name} must append to the registers"
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
    [end_states | rest] = %__MODULE__{code: code, regs: [[starting_map]]}
    |> do_analyze
    |> Map.get(:regs)

    type = rest
    |> List.last   # grab the end states
    |> Enum.zip(end_states)
    |> Enum.map(fn {params, return} ->
      %Type.Function{params: Map.values(params), return: return[0]}
    end)
    |> Enum.into(%Type.Union{})

    {:ok, type}
  end

  def do_analyze(state = %{code: [], regs: registers}), do: state
  def do_analyze(state = %{code: [:bp_stop | _]}), do: state
  def do_analyze(state) do
    state
    |> do_infer
    |> do_analyze
  end

  opcode {:move, from, {:x, to}}, state do
    put_reg(state, to, type_of(state, from))
  end

  opcode {:gc_bif, :bit_size, {:f, to}, 1, [x: from], _}, state do
    state
    |> backpropagate(%{from => %Type.Bitstring{size: 0, unit: 1}})
    |> put_reg(to, builtin(:non_neg_integer))
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
  opcode :return

  def do_infer(opcode, _, _) do
    raise "unknown opcode #{inspect opcode}"
  end

  def backpropagate(state = %{stack: stack, regs: [[head_reg] | rest]}, delta) do
    new_reg = delta
    |> Map.keys
    |> Enum.map(fn key -> {key, Type.intersection(delta[key], head_reg[key])} end)
    |> Enum.into(head_reg)

    if new_reg == head_reg do
      # then do nothing, move on.
      state
    else
      do_backprop(%{state | stack: [:bp_stop | stack], regs: [[new_reg], [new_reg] | rest]})
    end
  end

  def do_backprop(state = %{regs: [regs_init]}) do
    # restart the analysis once we're at the top.
    do_analyze(state)
  end
  def do_backprop(state = %{code: code, stack: [stack_head | stack_rest], regs: [head, _ | rest]}) do
    # for now, just ignore the effects that functions have
    do_backprop(%{state | code: [stack_head | code], stack: stack_rest, regs: [head | rest]})
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
