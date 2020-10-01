defmodule MavisTest.Opcode.FuncInfoTest do
  use ExUnit.Case, async: true

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Function, Inference}

  test "funcinfo full integration" do
    code = [{:func_info, {:atom, :module}, {:atom, :func}, 2}]

    assert {:ok, %Function{
      params: [builtin(:any)], return: builtin(:any)
    }} = Inference.run(code, %{0 => builtin(:any)})
  end
end
