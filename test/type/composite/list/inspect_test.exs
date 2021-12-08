defmodule TypeTest.List.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  pull_types(defmodule Lists do
    @type proper_list :: [atom]  # note that this is handled by the "Union" type
    @type nonempty_any_list :: [...]
    @type nonempty_type_list :: [atom, ...]
    @type keyword_list :: [foo: atom]  # note that this is handled by the "Union" type
    @type two_keyword_list :: [foo: atom, bar: atom]  # note that this is handled by the "Union" type
    @type two_different_keyword_list :: [foo: atom, bar: float]  # note that this is handled by the "Union" type
    @type three_keyword_list :: [foo: atom, bar: float, baz: atom]  # note that this is handled by the "Union" type
  end)

  describe "the proper list type" do
    test "looks like itself" do
      assert "type([atom()])" == inspect(@proper_list)
    end

    test "code translates correctly" do
      assert @proper_list == eval_inspect(@proper_list)
    end
  end

  describe "the nonempty list type" do
    test "looks like itself" do
      assert "type([...])" == inspect(@nonempty_any_list)
    end

    test "code translates correctly" do
      assert @nonempty_any_list == eval_inspect(@nonempty_any_list)
    end
  end

  describe "the nonempty typed list" do
    test "looks like itself" do
      assert "type([atom(), ...])" == inspect(@nonempty_type_list)
    end

    test "code translates correctly" do
      assert @nonempty_type_list == eval_inspect(@nonempty_type_list)
    end
  end

  describe "the keyword list" do
    test "looks like itself" do
      assert "type([foo: atom()])" == inspect(@keyword_list)
    end

    test "code translates correctly" do
      assert @keyword_list == eval_inspect(@keyword_list)
    end
  end

  describe "the multi-keyword list" do
    test "looks like itself" do
      assert "type([foo: atom(), bar: atom()])" == inspect(@two_keyword_list)
    end

    test "code translates correctly" do
      assert @two_keyword_list == eval_inspect(@two_keyword_list)
    end
  end

  describe "keywords that aren't collapsed" do
    test "looks like itself" do
      assert "type([foo: atom(), bar: atom()])" == inspect(@two_keyword_list)
    end

    test "code translates correctly" do
      assert @two_keyword_list == eval_inspect(@two_keyword_list)
    end
  end

  describe "collapsible keywords" do
    test "looks like itself" do
      assert "type([foo: atom(), baz: atom(), bar: float()])" == inspect(@three_keyword_list)
    end

    test "code translates correctly" do
      assert @three_keyword_list == eval_inspect(@three_keyword_list)
    end
  end
end
