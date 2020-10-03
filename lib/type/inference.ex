defmodule Type.Inference do

  require Type.Inference.Macros
  import Type.Inference.Macros

  @enforce_keys [:code, :regs]
  defstruct @enforce_keys ++ [
    stack: []
  ]

  @type opcode :: atom | tuple
  @type reg_state :: %{
    optional(integer) => Type.t,
    optional(:line) => non_neg_integer,
    optional(:warn) => any}

  @type state :: %__MODULE__{
    code:  [opcode],
    stack: [opcode],
    regs:  [[reg_state]]
  }

  def run(code, starting_map, module \\ __MODULE__.Opcodes) do
    [end_states | rest] = %__MODULE__{code: code, regs: [[starting_map]]}
    |> do_analyze(module)
    |> Map.get(:regs)

    initial_registers = Map.keys(starting_map)

    type = rest
    |> List.last   # grab the initial registry states
    |> Enum.zip(end_states)
    |> Enum.map(fn {params, return} ->

      # we need to filter out "old" values since some values
      # could have been padded in by clobbering opcodes
      init_params = Enum.flat_map(params, fn {k, v} ->
        if k in initial_registers, do: [v],else: []
      end)

      %Type.Function{params: init_params, return: return[0]}
    end)
    |> Enum.into(%Type.Union{})

    {:ok, type}
  end

  def do_analyze(state = %{code: []}, _), do: state
  def do_analyze(state, module) do
    state
    |> do_forward(module)
    |> do_backprop(module)
    |> do_analyze(module)
  end

  def do_forward(state, module \\ __MODULE__.Opcodes)
  def do_forward(state = %{code: [instr | _], regs: [[latest] | _]}, module) do
    state
    |> push_reg([module.forward(instr, latest)])
    |> shift
  end
  def do_forward(state = %{regs: [[] | _]}, _) do
    state
    |> push_reg([])
    |> shift
  end

  def do_backprop(state, module \\ __MODULE__.Opcodes)
  def do_backprop(state = %{stack: []}, module) do
    # if we've run out of stack, then run the forward propagation.
    do_analyze(state, module)
  end
  def do_backprop(state, module) do
    # performs backpropagation on the current state.
    # first, run the backpropagation and answer the question:
    # did we need to change any of the forward enties.
    %{stack: [this | _], regs: [[latest], [prev] | _]} = state

    case module.backprop(this, latest) do
      {:ok, ^prev} ->
        state
      {:ok, replacement} ->
        state
        |> pop_reg_replace([replacement])
        |> unshift
        |> do_backprop(module)
      {:error, _} ->
        %{state | regs: [[] | tl(state.regs)]}
    end
  end

end
