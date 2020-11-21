defmodule TypeTest.TypeMap.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.Map

  @any any()
  @any_map map()
  @empty_map %Map{}

  describe "the empty map type" do
    test "is usable as itself, any map, and any" do
      assert :ok = @empty_map ~> @empty_map
      assert :ok = @empty_map ~> @any_map
      assert :ok = @empty_map ~> @any
    end

    test "is usable as map with optional types" do
      assert :ok = @empty_map ~> map(%{optional(:foo) => @any})
    end

    test "is not usable as a map with required types" do
      assert {:error, _} = @empty_map ~> map(%{foo: @any})
    end
  end

  describe "a map with a required type" do
    test "is usable as a map with the same type required" do
      assert :ok = map(%{foo: :bar}) ~> map(%{foo: :bar})
      assert :ok = map(%{foo: :bar}) ~> map(%{foo: atom()})
      assert :ok = map(%{foo: :bar}) ~> map(%{atom() => atom()})
    end

    test "is usable as a map with optional type" do
      assert :ok = map(%{foo: :bar}) ~> map(%{optional(:foo) => :bar})
      assert :ok = map(%{foo: :bar}) ~> map(%{optional(:foo) => atom()})
      assert :ok = map(%{foo: :bar}) ~> map(%{atom() => atom()})
    end

    test "is maybe usable if the target value type is a subtype" do
      assert {:maybe, _} = map(%{foo: integer()}) ~> map(%{optional(:foo) => 1..10})
      assert {:maybe, _} = map(%{foo: integer()}) ~> map(%{atom() => 1..10})
    end

    test "is not usable as a map without the type in its preimage" do
      assert {:error, _} = map(%{foo: :bar}) ~> map(%{baz: :quux})
      assert {:error, _} = map(%{foo: :bar}) ~> map(%{integer() => @any})
    end
  end

  describe "a map with an optional type" do
    test "is usable as a map with the same type optional" do
      assert :ok = map(%{optional(:foo) => :bar}) ~> map(%{optional(:foo) => :bar})
      assert :ok = map(%{optional(:foo) => :bar}) ~> map(%{optional(:foo) => atom()})

      assert :ok = map(%{integer() => :bar}) ~>
        map(%{integer() => atom()})

      assert :ok = map(%{integer() => :bar}) ~>
        map(%{neg_integer() => :bar, non_neg_integer() => atom()})
    end

    test "is usable as a map with a bigger type optional" do
      assert :ok = map(%{optional(:foo) => :bar}) ~> map(%{atom() => :bar})
      assert :ok = map(%{optional(:foo) => :bar}) ~> map(%{atom() => :bar})
    end

    test "is maybe usable if the target type is required" do
      assert {:maybe, _} = map(%{optional(:foo) => :bar}) ~> map(%{foo: :bar})
      assert {:maybe, _} = map(%{atom() => :bar}) ~> map(%{foo: :bar})
    end

    test "is maybe usable if the key type is bigger" do
      assert {:maybe, _} = map(%{atom() => :bar}) ~> map(%{foo: :bar})

      # note that zero isn't in the target space
      assert {:maybe, _} = map(%{integer() => :foo}) ~>
                             map(%{neg_integer() => :foo,
                                   pos_integer() => atom()})
    end

    test "is maybe usable if the value type is smaller" do
      assert {:maybe, _} = map(%{optional(:foo) => atom()}) ~> map(%{optional(:foo) => :bar})
    end

    test "is maybe usable if the value type is disjoint" do
      # the empty map satisfies both sides quite well.
      assert {:maybe, _} = map(%{optional(:foo) => :bar}) ~> map(%{optional(:foo) => :baz})
    end

    test "is maybe usable even if the whole thing is disjoint" do
      # note that here empty map is acceptable as both types.
      assert {:maybe, _} = map(%{optional(:foo) => atom()}) ~> map(%{optional(:bar) => atom()})
    end

    test "is not usable if the target type has a required key" do
      assert {:error, _} = map(%{optional(:foo) => atom()}) ~> map(%{bar: atom()})
    end

    test "is not usable if the target type has a required key but the value is the wrong type" do
      assert {:error, _} = map(%{optional(:foo) => atom()}) ~> map(%{foo: integer()})
    end
  end

  describe "when a map has multiple optional fields which overlap" do
    @dual_map map(%{optional(:foo) => neg_integer() <|> nil,
                    atom() => pos_integer() <|> nil})
    @dual_req map(%{atom() => pos_integer() <|> nil,
                    foo: neg_integer() <|> nil})

    test "if a map fulfills both it is usable" do
      assert :ok = map(%{optional(:foo) => nil}) ~> @dual_map
      assert :ok = map(%{foo: nil}) ~> @dual_req
    end

    test "if a map does not fulfill both it is not usable" do
      ## when the target type has optional overlap
      # if it's optional, not having the parameter is valid.
      assert {:maybe, _} = map(%{optional(:foo) => -1}) ~> @dual_map
      assert {:maybe, _} = map(%{optional(:foo) => 1}) ~> @dual_map
      # if it's a required parameter we won't be happy.
      assert {:error, _} = map(%{foo: -1}) ~> @dual_map
      assert {:error, _} = map(%{foo: 1}) ~> @dual_map

      ## when the target type has an overlap in required, it's toast.
      assert {:error, _} = map(%{optional(:foo) => -1}) ~> @dual_req
      assert {:error, _} = map(%{optional(:foo) => 1}) ~> @dual_req
      assert {:error, _} = map(%{foo: -1}) ~> @dual_req
      assert {:error, _} = map(%{foo: 1}) ~> @dual_req
    end
  end
end
