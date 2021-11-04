defmodule TypeTest.BuiltinIdentifier.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the identifier type" do
    pull_types(defmodule Identifier do
      @type identifier_type :: identifier
      @type identifier_plus :: identifier | nil
    end)

    test "looks like a identifier" do
      assert "identifier()" == inspect(@identifier_type)
    end

    test "code translates correctly" do
      assert @identifier_type == eval_inspect(@identifier_type)
    end

    test "identifier plus works" do
      assert "identifier() <|> nil" = inspect(@identifier_plus)
    end
  end
end
