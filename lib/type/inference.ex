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

  def run(code, starting_map, module \\ __MODULE__.Opcodes) do
    [end_states | rest] = %__MODULE__{code: code, regs: [[starting_map]]}
    |> do_analyze(module)
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

  def do_analyze(state = %{code: []}, _), do: state
  def do_analyze(state, module) do
    state
    |> module.forward
    |> do_analyze(module)
  end

end
