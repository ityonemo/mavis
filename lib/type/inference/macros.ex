defmodule Type.Inference.Macros do
  defmacro __using__(_) do
    quote do
      @behaviour Type.Inference.Api

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

        {fwd_ast, reg_ast, {:ok, {:reg, [], Elixir}}, {:reg, [], Elixir}}
    end

    # to prevent compiler warnings that can happen if only some of
    free_vars = scan_free_vars(op_ast)

    fwd_suppress = free_vars -- scan_free_vars(fwd_ast)
    bck_suppress = free_vars -- scan_free_vars(bck_ast)

    fwd_op = suppress(op_ast, fwd_suppress)
    bck_op = suppress(op_ast, bck_suppress)

    fwd = quote do
      def forward(unquote(fwd_op), unquote(freg_ast)) do
        unquote(fwd_ast)
      end
    end

    bck = quote do
      def backprop(unquote(bck_op), unquote(breg_ast)) do
        unquote(bck_ast)
      end
    end

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
      def backprop(unquote(op_ast), registers), do: {:ok, registers}
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

  ################################################################
  ## DSL tools

  @var_endings [nil, Elixir]

  defp scan_free_vars({ast, _, params}) when is_list(params) do
    scan_free_vars(ast) ++ Enum.flat_map(params, &scan_free_vars/1)
  end
  defp scan_free_vars({a, _, b}) when is_atom(a) and b in @var_endings do
    case Atom.to_string(a) do
      "_" <> _ -> []
      _ -> [a]
    end
  end
  defp scan_free_vars({a, b}) do
    scan_free_vars(a) ++ scan_free_vars(b)
  end
  defp scan_free_vars(lst) when is_list(lst) do
    Enum.flat_map(lst, &scan_free_vars/1)
  end
  defp scan_free_vars(atom) when is_atom(atom), do: []
  defp scan_free_vars(number) when is_number(number), do: []
  defp scan_free_vars(binary) when is_binary(binary), do: []

  defp suppress(ast, []), do: ast
  defp suppress({ast, meta, params}, deadlist) when is_list(params) do
    {suppress(ast, deadlist), meta, Enum.map(params, &suppress(&1, deadlist))}
  end
  defp suppress({a, b}, deadlist) do
    {suppress(a, deadlist), suppress(b, deadlist)}
  end
  defp suppress({a, meta, b}, deadlist) when is_atom(a) and b in @var_endings do
    if a in deadlist do
      silenced_a = String.to_atom("_#{a}")
      {silenced_a, meta, b}
    else
      {a, meta, b}
    end
  end
  defp suppress(list, deadlist) when is_list(list) do
    Enum.map(list, &suppress(&1, deadlist))
  end
  defp suppress(any, _), do: any

end
