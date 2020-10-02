defmodule TypeTest.Opcode.MoveTest do
  # various ways that the move opcode can be a thing

  use ExUnit.Case, async: true
  import TypeTest.OpcodeCase

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Function, Inference}

  describe "move opcode register move" do
    test "forward propagation" do
      assert %{regs: [[%{0 => :foo}] | _]} =
        Inference.Opcodes.forward(%Inference{
          code: [{:move, {:x, 1}, {:x, 0}}],
          regs: [[%{1 => :foo}]]
        })

      assert %{regs: [[%{1 => :foo}] | _]} =
        Inference.Opcodes.forward(%Inference{
          code: [{:move, {:x, 0}, {:x, 1}}],
          regs: [[%{0 => :foo}]]
        })
    end

    test "backward propagation" do
      assert %{regs: [[%{0 => builtin(:any), 1 => :foo}]]} =
        Inference.Opcodes.backprop(%Inference{
          code: [],
          stack: [{:move, {:x, 1}, {:x, 0}}],
          regs: [[%{0 => :foo}], [%{1 => builtin(:any)}]]
        })
    end

    test "backward propagation mismatch"

    test "integration test" do
      code = [{:move, {:x, 1}, {:x, 0}}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{1 => builtin(:any)})
    end
  end

  describe "move opcode literal integer move" do
    test "forward propagation" do
      assert %{regs: [[%{0 => 47}] | _]} =
        Inference.Opcodes.forward(%Inference{
          code: [{:move, {:integer, 47}, {:x, 0}}],
          regs: [[%{}]]
        })
    end

    test "backward propagation" do
      assert %{regs: [[%{0 => builtin(:any)}]]} =
        Inference.Opcodes.backprop(%Inference{
          code: [],
          stack: [{:move, {:integer, 47}, {:x, 0}}],
          regs: [[%{0 => 47}], [%{0 => :foo}]]
        })
    end

    test "backward propagation mismatch"

    test "integration test" do
      code = [{:move, {:integer, 47}, {:x, 0}}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: 47
      }} = Inference.run(code, %{0 => builtin(:any)})
    end
  end

  describe "move opcode atom literal move" do
    test "forward propagation" do
      assert %{regs: [[%{0 => :foo}] | _]} =
        Inference.Opcodes.forward(%Inference{
          code: [{:move, {:atom, :foo}, {:x, 0}}],
          regs: [[%{}]]
        })
    end

    test "backward propagation" do
      assert %{regs: [[%{0 => builtin(:any)}]]} =
        Inference.Opcodes.backprop(%Inference{
          code: [],
          stack: [{:move, {:integer, 47}, {:x, 0}}],
          regs: [[%{0 => :foo}], [%{0 => :xxx}]]
        })
    end

    test "backward propagation mismatch"

    test "integration test" do
      code = [{:move, {:atom, :foo}, {:x, 0}}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: :foo
      }} = Inference.run(code, %{0 => builtin(:any)})
    end
  end

  describe "move opcode string literal move" do
    test "forward propagation" do
      assert %{regs: [[%{0 => %Type{module: String, name: :t}}] | _]} =
        Inference.Opcodes.forward(%Inference{
          code: [{:move, {:literal, "foo"}, {:x, 0}}],
          regs: [[%{}]]
        })
    end

    test "backward propagation" do
      assert %{regs: [[%{0 => builtin(:any)}]]} =
        Inference.Opcodes.backprop(%Inference{
          code: [],
          stack: [{:move, {:literal, "foo"}, {:x, 0}}],
          regs: [[%{0 => %Type{module: String, name: :t}}], [%{0 => :foo}]]
        })
    end

    test "backward propagation mismatch"

    test "integration test" do
      code = [{:move, {:literal, "foo"}, {:x, 0}}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: %Type{module: String, name: :t}
      }} = Inference.run(code, %{0 => builtin(:any)})
    end
  end
end
