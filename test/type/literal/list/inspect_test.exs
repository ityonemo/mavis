defmodule TypeTest.LiteralList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the literal empty list type" do
    pull_types(defmodule LiteralEmptyList do
      @type literal_empty_list :: []
    end)

    test "looks like an empty list" do
      assert "[]" == inspect(@literal_empty_list)
    end

    test "code translates correctly" do
      assert @literal_empty_list == eval_inspect(@literal_empty_list)
    end
  end

  describe "the literal nonempty list" do
    @literal_nonempty_list [:foo, "bar"]

    test "looks like a nonempty list" do
      assert ~s([:foo, "bar"]) == inspect(@literal_nonempty_list)
    end

    test "code translates correctly" do
      assert @literal_nonempty_list == eval_inspect(@literal_nonempty_list)
    end
  end

  describe "the literal improper list" do
    @literal_improper_list [:foo | "bar"]

    test "looks like an improper list" do
      assert ~s([:foo | "bar"]) == inspect(@literal_improper_list)
    end

    test "code translates correctly" do
      assert @literal_improper_list == eval_inspect(@literal_improper_list)
    end
  end
end
