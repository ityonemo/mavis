defmodule TypeTest.Function.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  pull_types(defmodule Functions do
    @type any_fun :: (... -> any())
    @type zero_arity :: (-> :foo)
    @type one_arity :: (:foo -> :foo)
    @type two_arity :: (:foo, :bar -> :foo)
    @type any_arity :: (... -> :foo)

    @spec multi_branch(:foo) :: :bar
    @spec multi_branch(:bar) :: :baz
    def multi_branch(:foo), do: :bar
    def multi_branch(:bar), do: :baz
  end)

  describe "the any function type" do
    test "looks like function" do
      assert "function()" == inspect(@any_fun)
    end

    test "code translates correctly" do
      assert @any_fun == eval_inspect(@any_fun)
    end
  end

  describe "the zero arity function type" do
    test "looks like itself" do
      assert "type(( -> :foo))" == inspect(@zero_arity)
    end

    test "code translates correctly" do
      assert @zero_arity == eval_inspect(@zero_arity)
    end
  end

  describe "the one arity function type" do
    test "looks like itself" do
      assert "type((:foo -> :foo))" == inspect(@one_arity)
    end

    test "code translates correctly" do
      assert @one_arity == eval_inspect(@one_arity)
    end
  end

  describe "the two arity function type" do
    test "looks like itself" do
      assert "type((:foo, :bar -> :foo))" == inspect(@two_arity)
    end

    test "code translates correctly" do
      assert @two_arity == eval_inspect(@two_arity)
    end
  end

  describe "the any arity function type" do
    test "looks like itself" do
      assert "type((... -> :foo))" == inspect(@any_arity)
    end

    test "code translates correctly" do
      assert @any_arity == eval_inspect(@any_arity)
    end
  end

  describe "the multi-branch function type" do
    test "uses the ||| operator" do
      assert "(:foo -> :bar) ||| (:bar -> :baz)" == inspect(@multi_branch)
    end

    test "code translates correctly" do
      assert @multi_branch == eval_inspect(@multi_branch)
    end
  end

  @top_arity %Type.Function{branches: [%Type.Function.Branch{params: 2, return: :foo}]}

  describe "the top-arity function type" do
    test "gets underscores" do
      assert "type((_, _ -> :foo))" == inspect(@top_arity)
    end

    test "code translates correctly" do
      assert @top_arity == eval_inspect(@top_arity)
    end
  end
end
