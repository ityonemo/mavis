defmodule TypeTest.TypeMap.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]
  use Type.Operators

  alias Type.Map

  @any builtin(:any)
  @any_map Map.build(%{@any => @any})
  @empty_map %Map{}

  describe "the empty map type" do
    test "is usable as itself, any map, and any" do
      assert :ok = @empty_map ~> @empty_map
      assert :ok = @empty_map ~> @any_map
      assert :ok = @empty_map ~> @any
    end

    test "is usable as map with optional types" do
      assert :ok = @empty_map ~> Map.build(foo: @any)
    end

    test "is not usable as a map with required types" do
      assert {:error, _} = @empty_map ~> Map.build(%{foo: @any}, %{})
    end
  end

  describe "a map with a required type" do
    test "is usable as a map with the same type required" do
      assert :ok = Map.build(%{foo: :bar}, %{}) ~> Map.build(%{foo: :bar}, %{})
      assert :ok = Map.build(%{foo: :bar}, %{}) ~> Map.build(%{foo: builtin(:atom)}, %{})
      assert :ok = Map.build(%{foo: :bar}, %{}) ~> Map.build(%{builtin(:atom) => builtin(:atom)})
    end

    test "is usable as a map with optional type" do
      assert :ok = Map.build(%{foo: :bar}, %{}) ~> Map.build(foo: :bar)
      assert :ok = Map.build(%{foo: :bar}, %{}) ~> Map.build(foo: builtin(:atom))
      assert :ok = Map.build(%{foo: :bar}, %{}) ~> Map.build(%{builtin(:atom) => builtin(:atom)})
    end

    test "is maybe usable if the target value type is a subtype" do
      assert {:maybe, _} = Map.build(%{foo: builtin(:integer)}, %{}) ~>
                             Map.build(foo: 1..10)
      assert {:maybe, _} = Map.build(%{foo: builtin(:integer)}, %{}) ~>
                             Map.build(%{builtin(:atom) => 1..10})
    end

    test "is not usable as a map without the type in its domain" do
      assert {:error, _} = Map.build(%{foo: :bar}, %{}) ~> Map.build(baz: :quux)
      assert {:error, _} = Map.build(%{foo: :bar}, %{}) ~> Map.build(%{builtin(:integer) => @any})
    end
  end

  describe "a map with an optional type" do
    test "is usable as a map with the same type optional" do
      assert :ok = Map.build(foo: :bar) ~> Map.build(foo: :bar)
      assert :ok = Map.build(foo: :bar) ~> Map.build(foo: builtin(:atom))

      assert :ok = Map.build(%{builtin(:integer) => :bar}) ~>
                     Map.build(%{builtin(:integer) => builtin(:atom)})

      assert :ok = Map.build(%{builtin(:integer) => :bar}) ~>
                     Map.build(%{
                       builtin(:neg_integer) => :bar,
                       builtin(:non_neg_integer) => builtin(:atom)})
    end

    test "is usable as a map with a bigger type optional" do
      assert :ok = Map.build(foo: :bar) ~> Map.build(%{builtin(:atom) => :bar})
      assert :ok = Map.build(foo: :bar) ~> Map.build(%{builtin(:atom) => :bar})
    end

    test "is maybe usable if the target type is required" do
      assert {:maybe, _} = Map.build(foo: :bar) ~> Map.build(%{foo: :bar}, %{})
      assert {:maybe, _} = Map.build(%{builtin(:atom) => :bar}) ~> Map.build(%{foo: :bar}, %{})
    end

    test "is maybe usable if the key type is bigger" do
      assert {:maybe, _} = Map.build(%{builtin(:atom) => :foo}) ~>
                             Map.build(foo: :bar)

      # note that the space in front is a bit too big.
      assert {:maybe, _} = Map.build(%{builtin(:integer) => :foo}) ~>
                             Map.build(%{
                                builtin(:neg_integer) => :bar,
                                builtin(:pos_integer) => builtin(:atom)})
    end

    test "is maybe usable if the value type is smaller" do
      assert {:maybe, _} = Map.build(foo: builtin(:atom)) ~> Map.build(foo: :bar)
    end

    test "is maybe usable if the value type is disjoint" do
      # the empty map satisfies both sides quite well.
      assert {:maybe, _} = Map.build(foo: :bar) ~> Map.build(foo: :baz)
    end

    test "is maybe usable even if the whole thing is disjoint" do
      # note that here empty map is acceptable as both types.
      assert {:maybe, _} = Map.build(foo: builtin(:atom)) ~> Map.build(bar: builtin(:atom))
    end

    test "is not usable if the target type has a required key" do
      assert {:error, _} = Map.build(foo: builtin(:atom)) ~>
        Map.build(%{bar: builtin(:atom)}, %{})
    end

    test "is not usable if the target type has a required key but the value is the wrong type" do
      assert {:error, _} = Map.build(foo: builtin(:atom)) ~>
        Map.build(%{foo: builtin(:integer)}, %{})
    end
  end

  describe "when a map has multiple optional fields which overlap" do
    @dual_map Map.build(%{:foo => builtin(:neg_integer) <|> nil,
                          builtin(:atom) => builtin(:pos_integer) <|> nil})
    @dual_req Map.build(%{foo: builtin(:neg_integer) <|> nil},
                        %{builtin(:atom) => builtin(:pos_integer) <|> nil})

    test "if a map fulfills both it is usable" do
      assert :ok = Map.build(foo: nil) ~> @dual_map
      assert :ok = Map.build(%{foo: nil}, %{}) ~> @dual_req
    end

    test "if a map does not fulfill both it is not usable" do
      ## when the target type has optional overlap
      # if it's optional, not having the parameter is valid.
      assert {:maybe, _} = Map.build(foo: -1) ~> @dual_map
      assert {:maybe, _} = Map.build(foo: 1) ~> @dual_map
      # if it's a required parameter we won't be happy.
      assert {:error, _} = Map.build(%{foo: -1}, %{}) ~> @dual_map
      assert {:error, _} = Map.build(%{foo: 1}, %{}) ~> @dual_map

      ## when the target type has an overlap in required, it's toast.
      assert {:error, _} = Map.build(foo: -1) ~> @dual_req
      assert {:error, _} = Map.build(foo: 1) ~> @dual_req
      assert {:error, _} = Map.build(%{foo: -1}, %{}) ~> @dual_req
      assert {:error, _} = Map.build(%{foo: 1}, %{}) ~> @dual_req
    end
  end
end
