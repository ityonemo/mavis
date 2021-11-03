defmodule TypeTest.Union.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  pull_types(defmodule Union do
    @type union :: :foo | :bar
  end)

  describe "the union type" do
    test "gets rendered using operators" do
      assert ":bar <|> :foo" == inspect(@union)
    end

    test "code translates correctly" do
      assert @union == eval_inspect(@union)
    end
  end
end
