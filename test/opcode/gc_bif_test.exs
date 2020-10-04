defmodule TypeTest.Opcode.GcBifTest do

  # various ways that the move opcode can be a thing

  use ExUnit.Case, async: true

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Bitstring, Function, Inference}

  describe "bit_size bif" do
    defp gc_bit_size(src, dst) do
      {:gc_bif, :bit_size, {:f, dst}, 1, [x: src], {:x, src}}
    end

    test "forward propagation" do
      assert %{regs: [[%{0 => builtin(:non_neg_integer)}] | _]} =
        Inference.do_forward(%Inference{
          code: [gc_bit_size(1, 0)],
          regs: [[%{1 => builtin(:any)}]]
        })

      assert %{regs: [[%{1 => builtin(:non_neg_integer)}] | _]} =
        Inference.do_forward(%Inference{
          code: [gc_bit_size(0, 1)],
          regs: [[%{0 => builtin(:any)}]]
        })
    end

    test "backward propagation" do
      assert %{regs: regs} =
        Inference.do_backprop(%Inference{
          code: [],
          stack: [gc_bit_size(0, 0)],
          regs: [[%{0 => builtin(:non_neg_integer)}], [%{0 => builtin(:any)}]]
        })

      assert [%{0 => %Bitstring{size: 0, unit: 1}}] = List.last(regs)
    end

    test "integration" do
      assert {:ok, %Function{
        params: [%Bitstring{size: 0, unit: 1}],
        return: builtin(:non_neg_integer)
      }} = Inference.run([gc_bit_size(0, 0)], %{0 => builtin(:any)})
    end
  end
end
