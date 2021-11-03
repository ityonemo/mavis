defmodule TypeTest.BuiltinKeyword.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the keyword type" do
    pull_types(defmodule Keyword do
      @type keyword_type :: keyword
    end)

    test "looks like a keyword" do
      assert "keyword()" == inspect(@keyword_type)
    end

    test "code translates correctly" do
      assert @keyword_type == eval_inspect(@keyword_type)
    end
  end
end
