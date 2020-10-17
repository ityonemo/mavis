defmodule TypeTest.RegressionTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  describe "regression where File.copy spec infinite loops" do
    # initial failing example
    test "File.copy/3 spec can be loaded" do
      assert {:ok, _} = Type.fetch_spec(File, :copy, 3)
    end

    # reduced to the major culprit:
    test "Path.t/0 spec can be unioned" do
      assert %Type.Union{} = remote(Path.t()) <|> remote(:file.io_device())
    end

    # failing typespec:
    test "Path.t/0 type can be fetched" do
      assert {:ok, _} = Type.fetch_type(Path, :t)
    end

    # reduced to the following builtin:
    test "IO.chardata/0 type can be fetched" do
      assert {:ok, _} = Type.fetch_type(IO, :chardata)
    end

    # reduced to an even smaller condition:
    test "recursive lists" do
      assert {:ok, _} = Type.fetch_type(TypeTest.TypeExample, :regression_1)
    end

    # reduced to a specific failing function:
    test "specific problem with typegroup" do
      type = remote(TypeTest.TypeExample.regression_1())
      assert 0 == Type.typegroup(type)
    end
  end

  describe "regression with obtaining type of Macro.output_expr" do
    test "Macro.output_expr/0 can be loaded" do
      assert {:ok, _} = Type.fetch_type(Macro, :output_expr, [])
    end
  end
end
