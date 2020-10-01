defmodule MavisTest.Opcode.MoveTest do

  # various ways that the move opcode can be a thing

  use ExUnit.Case, async: true

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Function, Inference}

  describe "move variable opcode with register index" do
    test "integration" do
      code = [{:move, {:x, 1}, {:x, 0}}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{1 => builtin(:any)})
    end
  end

  describe "move variable opcode with literal values" do
    test "integer integration test" do
      code = [{:move, {:integer, 47}, {:x, 0}}]
      assert {:ok, %Function{
        params: [], return: 47
      }} = Inference.run(code, %{})
    end

    test "atom integration test" do
      code = [{:move, {:atom, :foo}, {:x, 0}}]
      assert {:ok, %Function{
        params: [], return: :foo
      }} = Inference.run(code, %{})
    end

    test "literal string test" do
      code = [{:move, {:literal, "foo"}, {:x, 0}}]
      assert {:ok, %Function{
        params: [], return: %Type{module: String, name: :t}
      }} = Inference.run(code, %{})
    end
  end
end
