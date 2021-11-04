defmodule TypeTest.BuiltinNumber.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the number type" do
    pull_types(defmodule Number do
      @type number_type :: number()
      @type number_plus :: number() | nil
    end)

    test "is presented as itself" do
      assert "number()" == inspect(@number_type)
    end

    test "code translates correctly" do
      assert @number_type == eval_inspect(@number_type)
    end

    test "number plus translates correctly" do
      assert "number() <|> nil" == inspect(@number_plus)
    end
  end
end
