defmodule MavisTest.Opcode.MoveTest do

  # various ways that the move opcode can be a thing

  use ExUnit.Case, async: true

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Function, Inference}

  describe "bit_size sub-opcode" do
    test "integration" do
      code = [{:move, {:x, 1}, {:x, 0}}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{1 => builtin(:any)})
    end
  end
end
