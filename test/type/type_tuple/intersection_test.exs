defmodule TypeTest.TypeTuple.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  alias Type.Tuple

  @anytuple %Tuple{elements: :any}

  describe "any tuple" do
    test "intersects with any and self" do
      assert @anytuple == @anytuple <~> builtin(:any)
      assert @anytuple == @anytuple <~> @anytuple
    end

    test "turns into its counterparty" do
      assert %Tuple{elements: []} == @anytuple <~> %Tuple{elements: []}
      assert %Tuple{elements: [:foo]} == @anytuple <~> %Tuple{elements: [:foo]}
      assert %Tuple{elements: [:foo, builtin(:integer)]} ==
        @anytuple <~> %Tuple{elements: [:foo, builtin(:integer)]}
    end

    test "with unions works as expected" do
      assert %Tuple{elements: []} == @anytuple <~> (%Tuple{elements: []} <|> 1..10)
      assert builtin(:none) == @anytuple <~> (builtin(:atom) <|> builtin(:port))
    end

    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([@anytuple, %Tuple{elements: []}])
      |> Enum.each(fn target ->
        assert builtin(:none) == @anytuple <~> target
      end)
    end
  end

  describe "tuples with defined elements" do
    test "intersect with the cartesian intersection" do
      assert %Tuple{elements: [:foo]} ==
        %Tuple{elements: [:foo]} <~>
        %Tuple{elements: [builtin(:atom)]}
      assert %Tuple{elements: [:foo]} ==
        %Tuple{elements: [builtin(:atom)]} <~>
        %Tuple{elements: [:foo]}

      assert %Tuple{elements: [:foo, 47]} ==
        %Tuple{elements: [:foo, builtin(:integer)]} <~>
        %Tuple{elements: [builtin(:atom), 47]}
      assert %Tuple{elements: [:foo, 47]} ==
        %Tuple{elements: [builtin(:atom), builtin(:integer)]} <~>
        %Tuple{elements: [:foo, 47]}
      assert %Tuple{elements: [:foo, 47]} ==
        %Tuple{elements: [:foo, 47]} <~>
        %Tuple{elements: [builtin(:atom), builtin(:integer)]}
    end

    test "a single mismatch yields none" do
      assert builtin(:none) == %Tuple{elements: [:foo]} <~> %Tuple{elements: [:bar]}
      assert builtin(:none) == %Tuple{elements: [:foo, :bar]} <~> %Tuple{elements: [:bar, :bar]}
      assert builtin(:none) == %Tuple{elements: [:bar, :bar]} <~> %Tuple{elements: [:bar, :foo]}
    end
  end
end
