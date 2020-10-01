defmodule MavisTest.Opcode.GcBifTest do

  # various ways that the move opcode can be a thing

  use ExUnit.Case, async: true

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Bitstring, Function, Inference}

  describe "bit_size bif" do
    test "integration" do
      code = [{:gc_bif, :bit_size, {:f, 1}, 1, [x: 1], {:x, 1}}]

      assert {:ok, %Function{
        params: [%Bitstring{size: 0, unit: 1}],
        return: builtin(:non_neg_integer)
      }} = Inference.run(code, %{1 => builtin(:any)})
    end
  end
end
