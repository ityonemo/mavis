defmodule TypeTest.Opcode.MiscTest do

  # miscellaneous opcodes that don't do as much

  use ExUnit.Case, async: true

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Function, Inference}

  describe "funcinfo opcode" do
    test "integration" do
      code = [{:func_info, {:atom, :module}, {:atom, :func}, 2}]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{0 => builtin(:any)})
    end
  end

  describe "label opcode" do
    test "integration" do
      code = [label: 14]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{0 => builtin(:any)})
    end
  end

  describe "line opcode" do
    test "integration" do
      code = [line: 19]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{0 => builtin(:any)})
    end
  end

  describe "return upcode" do
    test "integration" do
      code = [:return]

      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run(code, %{0 => builtin(:any)})
    end
  end
end
