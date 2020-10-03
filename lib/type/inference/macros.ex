defmodule Type.Inference.Macros do

  alias Type.Inference

  defmacro __using__(_) do
    quote do
      import Type.Inference.Macros, only: [opcode: 1, opcode: 2]

      Module.register_attribute(__MODULE__, :forwards, accumulate: true)
      Module.register_attribute(__MODULE__, :backprops, accumulate: true)

      @before_compile Type.Inference.Macros
    end
  end

  defmacro opcode(op_ast, do: ast) do
    {fwd_ast, freg_ast, bck_ast, breg_ast} = case ast do
      {:__block__, _,
        [{:forward, _, [freg_ast, [do: fwd_ast]]},
        {:backprop, _, [breg_ast, [do: bck_ast]]}]} ->

        {fwd_ast, freg_ast, bck_ast, breg_ast}
      {:forward, _, [reg_ast, [do: fwd_ast]]} ->

        {fwd_ast, reg_ast, {:reg, [], Elixir}, {:reg, [], Elixir}}
    end

    fwd = quote do
      def forward(unquote(op_ast), unquote(freg_ast)) do
        unquote(fwd_ast)
      end
    end

    bck = quote do
      def backprop(unquote(op_ast), unquote(breg_ast)) do
        unquote(bck_ast)
      end
    end

    bck |> Macro.to_string |> IO.puts

    quote do
      @forwards unquote(Macro.escape(fwd))
      @backprops unquote(Macro.escape(bck))
    end
  end


  defmacro opcode(op_ast) do
    fwd = quote do
      def forward(unquote(op_ast), registers), do: registers
    end
    bck = quote do
      def backprop(unquote(op_ast), registers), do: registers
    end

    quote do
      @forwards unquote(Macro.escape(fwd))
      @backprops unquote(Macro.escape(bck))
    end
  end

  defmacro __before_compile__(env) do
    caller = env.module
    fwd = Module.get_attribute(caller, :forwards)
    bck = Module.get_attribute(caller, :backprops)
    {:__block__, [], Enum.reverse(bck ++ fwd)}
  end


  ###############################################################
  ## TOOLS!

  def shift(state = %{code: [this | rest], stack: stack}) do
    %{state | code: rest, stack: [this | stack]}
  end

  def unshift(state = %{code: code, stack: [this | rest]}) do
    %{state | code: [this | code], stack: rest}
  end

  def pop_reg(state = %{regs: [_ | rest]}) do
    %{state | regs: rest}
  end

  def pop_reg_replace(state = %{regs: [_, _ | rest]}, replacement) do
    %{state | regs: [replacement | rest]}
  end

  def push_reg(state = %{regs: regs}, new_reg) do
    %{state | regs: [new_reg | regs]}
  end

  def push_meta(state, key, value) do
    %{state | meta: Map.put(state.meta, key, value)}
  end
end
