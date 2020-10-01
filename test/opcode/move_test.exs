defmodule TypeTest.Opcode.MoveTest do
  # various ways that the move opcode can be a thing

  use ExUnit.Case, async: true
  import TypeTest.OpcodeCase

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Function, Inference}

  describe "move opcode register move" do
    test "forward propagation" do
      state = Inference.Opcodes.forward(%Inference{
        code: [{:move, {:x, 1}, {:x, 0}}],
        regs: [[%{1 => :foo}]]
      })

      # check that the type of the registers has been appropriatel
      # changed.
      assert %{regs: [[%{0 => :foo, 1 => :foo}] | _]} = state
    end

    test "integration" do
      code = [{:move, {:x, 1}, {:x, 0}}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{1 => builtin(:any)})
    end
  end
end
