defmodule TypeTest.TypeMap.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.Map


  @any_map map()
  @empty_map %Map{}

  describe "the empty map type" do
    test "is usable as itself, any map, and any" do
      assert :ok = @empty_map ~> @empty_map
      assert :ok = @empty_map ~> @any_map
      assert :ok = @empty_map ~> any()
    end

    test "is usable as map with optional types" do
      assert :ok = @empty_map ~> type(%{optional(:foo) => any()})
    end

    test "is not usable as a map with required types" do
      assert {:error, _} = @empty_map ~> type(%{foo: any()})
    end
  end

  describe "a map with a required type" do
    test "is usable as a map with the same type required" do
      assert :ok = type(%{foo: :bar}) ~> type(%{foo: :bar})
      assert :ok = type(%{foo: :bar}) ~> type(%{foo: atom()})
      assert :ok = type(%{foo: :bar}) ~> type(%{atom() => atom()})
    end

    test "is usable as a map with optional type" do
      assert :ok = type(%{foo: :bar}) ~> type(%{optional(:foo) => :bar})
      assert :ok = type(%{foo: :bar}) ~> type(%{optional(:foo) => atom()})
      assert :ok = type(%{foo: :bar}) ~> type(%{atom() => atom()})
    end

    test "is maybe usable if the target value type is a subtype" do
      assert {:maybe, _} = type(%{foo: integer()}) ~> type(%{optional(:foo) => 1..10})
      assert {:maybe, _} = type(%{foo: integer()}) ~> type(%{atom() => 1..10})
    end

    test "is not usable as a map without the type in its preimage" do
      assert {:error, _} = type(%{foo: :bar}) ~> type(%{baz: :quux})
      assert {:error, _} = type(%{foo: :bar}) ~> type(%{integer() => any()})
    end
  end

  describe "a map with an optional type" do
    test "is usable as a map with the same type optional" do
      assert :ok = type(%{optional(:foo) => :bar}) ~> type(%{optional(:foo) => :bar})
      assert :ok = type(%{optional(:foo) => :bar}) ~> type(%{optional(:foo) => atom()})

      assert :ok = type(%{integer() => :bar}) ~>
        type(%{integer() => atom()})

      assert :ok = type(%{integer() => :bar}) ~>
        type(%{neg_integer() => :bar, non_neg_integer() => atom()})
    end

    test "is usable as a map with a bigger type optional" do
      assert :ok = type(%{optional(:foo) => :bar}) ~> type(%{atom() => :bar})
      assert :ok = type(%{optional(:foo) => :bar}) ~> type(%{atom() => :bar})
    end

    test "is maybe usable if the target type is required" do
      assert {:maybe, _} = type(%{optional(:foo) => :bar}) ~> type(%{foo: :bar})
      assert {:maybe, _} = type(%{atom() => :bar}) ~> type(%{foo: :bar})
    end

    test "is maybe usable if the key type is bigger" do
      assert {:maybe, _} = type(%{atom() => :bar}) ~> type(%{foo: :bar})

      # note that zero isn't in the target space
      assert {:maybe, _} = type(%{integer() => :foo}) ~>
                             type(%{neg_integer() => :foo,
                                   pos_integer() => atom()})
    end

    test "is maybe usable if the value type is smaller" do
      assert {:maybe, _} = type(%{optional(:foo) => atom()}) ~> type(%{optional(:foo) => :bar})
    end

    test "is maybe usable if the value type is disjoint" do
      # the empty map satisfies both sides quite well.
      assert {:maybe, _} = type(%{optional(:foo) => :bar}) ~> type(%{optional(:foo) => :baz})
    end

    test "is maybe usable even if the whole thing is disjoint" do
      # note that here empty map is acceptable as both types.
      assert {:maybe, _} = type(%{optional(:foo) => atom()}) ~> type(%{optional(:bar) => atom()})
    end

    test "is not usable if the target type has a required key" do
      assert {:error, _} = type(%{optional(:foo) => atom()}) ~> type(%{bar: atom()})
    end

    test "is not usable if the target type has a required key but the value is the wrong type" do
      assert {:error, _} = type(%{optional(:foo) => atom()}) ~> type(%{foo: integer()})
    end
  end

  describe "when a map has multiple optional fields which overlap" do
    @dual_map type(%{optional(:foo) => neg_integer() <|> nil,
                    atom() => pos_integer() <|> nil})
    @dual_req type(%{atom() => pos_integer() <|> nil,
                    foo: neg_integer() <|> nil})

    test "if a map fulfills both it is usable" do
      assert :ok = type(%{optional(:foo) => nil}) ~> @dual_map
      assert :ok = type(%{foo: nil}) ~> @dual_req
    end

    test "if a map does not fulfill both it is not usable" do
      ## when the target type has optional overlap
      # if it's optional, not having the parameter is valid.
      assert {:maybe, _} = type(%{optional(:foo) => -1}) ~> @dual_map
      assert {:maybe, _} = type(%{optional(:foo) => 1}) ~> @dual_map
      # if it's a required parameter we won't be happy.
      assert {:error, _} = type(%{foo: -1}) ~> @dual_map
      assert {:error, _} = type(%{foo: 1}) ~> @dual_map

      ## when the target type has an overlap in required, it's toast.
      assert {:error, _} = type(%{optional(:foo) => -1}) ~> @dual_req
      assert {:error, _} = type(%{optional(:foo) => 1}) ~> @dual_req
      assert {:error, _} = type(%{foo: -1}) ~> @dual_req
      assert {:error, _} = type(%{foo: 1}) ~> @dual_req
    end
  end
end
