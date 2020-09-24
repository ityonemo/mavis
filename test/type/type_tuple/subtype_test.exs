defmodule TypeTest.TypeTuple.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Tuple

  @any_tuple %Tuple{elements: :any}

  describe "any tuples" do
    test "are subtypes of themselves and any" do
      assert @any_tuple ~> builtin(:any)
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([%Tuple{elements: []}])
      |> Enum.each(fn target ->
        refute @any_tuple in target
      end)
    end
  end

  describe "defined tuples" do
    test "are subtypes of any tuple and any" do
      assert %Tuple{elements: []} in @any_tuple
      assert %Tuple{elements: [builtin(:integer)]} in @any_tuple
      assert %Tuple{elements: [builtin(:atom), builtin(:integer)]} in @any_tuple

      assert %Tuple{elements: []} in builtin(:any)
      assert %Tuple{elements: [builtin(:integer)]} in builtin(:any)
      assert %Tuple{elements: [builtin(:atom), builtin(:integer)]} in builtin(:any)
    end

    test "are subtypes of themselves" do
      assert %Tuple{elements: []} in %Tuple{elements: []}
      assert %Tuple{elements: [builtin(:integer)]} in %Tuple{elements: [builtin(:integer)]}
      assert %Tuple{elements: [builtin(:atom), builtin(:integer)]} in %Tuple{elements: [builtin(:atom), builtin(:integer)]}
    end

    test "are subtypes when their elements are subtypes" do
      assert %Tuple{elements: [47]} in %Tuple{elements: [builtin(:integer)]}
      assert %Tuple{elements: [47, :foo]} in %Tuple{elements: [builtin(:integer), builtin(:atom)]}
    end

    test "is not a subtype on partial match" do
      refute %Tuple{elements: [47, :foo]} in %Tuple{elements: [builtin(:atom), builtin(:atom)]}
      refute %Tuple{elements: [47, :foo]} in %Tuple{elements: [builtin(:integer), builtin(:integer)]}
    end

    test "is not a subtype if the lengths don't agree" do
      refute %Tuple{elements: [builtin(:integer)]} in %Tuple{elements: [builtin(:integer), builtin(:integer)]}
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([%Tuple{elements: []}])
      |> Enum.each(fn target ->
        refute %Tuple{elements: []} in target
        refute %Tuple{elements: [builtin(:integer)]} in target
        refute %Tuple{elements: [builtin(:atom), builtin(:integer)]} in target
      end)
    end
  end
end
