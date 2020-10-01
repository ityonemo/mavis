defmodule Type.Inference.Macros do

  alias Type.Inference

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

  def shift(state = %{code: [this | rest], stack: stack}) do
    %{state | code: rest, stack: [this | stack]}
  end
end
