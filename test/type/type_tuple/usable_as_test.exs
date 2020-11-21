defmodule TypeTest.TypeTuple.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.Message

  @any_tuple tuple()
  @min_2_tuple tuple({...(min: 2)})

  describe "for the minimum size tuple types" do
    test "you can use it for itself and the builtin any" do
      assert :ok = @any_tuple ~> @any_tuple
      assert :ok = @any_tuple ~> any()

      assert :ok = @min_2_tuple ~> @min_2_tuple
    end

    test "you can use it as a less restrictive tuple" do
      assert :ok = @min_2_tuple ~> @any_tuple
    end

    test "you can use it in a union type" do
      assert :ok = @any_tuple ~> (@any_tuple <|> atom())
    end

    test "it might be usable as a specified tuple" do
      # zero arity
      assert {:maybe, _} = @any_tuple ~> tuple({})
      # one arity
      assert {:maybe, _} = @any_tuple ~> tuple({:foo})
      # two arity
      assert {:maybe, _} = @any_tuple ~> tuple({integer(), atom()})
      assert {:maybe, _} = @min_2_tuple ~> tuple({:ok, integer()})
    end

    test "you can maybe use it as a more restrictive tuple" do
      assert {:maybe, _} = @any_tuple ~> @min_2_tuple
    end

    test "you can't use it in a union type of orthogonal types" do
      assert {:error, _} = @any_tuple ~> (integer() <|> :infinity)
    end

    test "you can't use it as a tuple that's too small" do
      assert {:error, _} = tuple({...(min: 3)}) ~>
        tuple({:ok, binary()})
    end

    test "you can't use it for anything else" do
      targets = TypeTest.Targets.except([tuple({})])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: @any_tuple, target: ^target}} =
          (@any_tuple ~> target)
      end)
    end
  end

  describe "for specified tuples" do
    test "they are usable as any tuple" do
      assert :ok = tuple({}) ~> @any_tuple
      assert :ok = tuple({:foo}) ~> @any_tuple
      assert :ok = tuple({integer(), atom()}) ~> @any_tuple
    end

    test "they are usable as mininum arity tuples" do
      assert :ok = tuple({:ok, integer()}) ~> @min_2_tuple
      assert :ok = tuple({:ok, binary(), integer()}) ~> @min_2_tuple
    end

    test "they are usable as tuples with the same length and transitive usable_as" do
      assert :ok = tuple({}) ~> tuple({})
      assert :ok = tuple({:foo}) ~> tuple({:foo})
      assert :ok = tuple({:foo}) ~> tuple({atom()})

      assert :ok = tuple({integer(), atom()}) ~>
        tuple({integer(), any()})

      assert :ok = tuple({integer(), atom()}) ~>
        tuple({any(), atom()})
    end

    test "tuple lengths must match" do
      assert {:error, _} = tuple({}) ~> tuple({integer()})
      assert {:error, _} = tuple({}) ~> tuple({integer(), any()})

      assert {:error, _} = tuple({integer()}) ~> tuple({})
      assert {:error, _} = tuple({integer()}) ~> tuple({integer(), any()})

      assert {:error, _} = tuple({integer(), any()}) ~> tuple({})
      assert {:error, _} = tuple({integer(), any()}) ~> tuple({integer()})
    end

    test "for a one-tuple it's the expected match of the single element" do
      assert {:maybe, _} = tuple({integer()}) ~> tuple({1..10})
      assert {:error, _} = tuple({integer()}) ~> tuple({atom()})
    end

    test "you can't use it as a tuple for which it doesn't have enough" do
      assert {:error, _} = tuple({:ok, integer()}) ~> tuple({...(min: 3)})
    end

    test "for a two-tuple it's the ternary logic match of all elements" do
      # OK MAYBE
      assert {:maybe, _} =
        tuple({integer(), integer()}) ~>
        tuple({integer(), 0..42})

      # OK ERROR
      assert {:error, _} =
        tuple({integer(), integer()}) ~>
        tuple({integer(), atom()})

      # MAYBE OK
      assert {:maybe, _} =
        tuple({integer(), integer()}) ~>
        tuple({0..42,             integer()})

      # MAYBE MAYBE
      assert {:maybe, _} =
        tuple({integer(), integer()}) ~>
        tuple({0..42,             0..42})

      # MAYBE ERROR
      assert {:error, _} =
        tuple({integer(), integer()}) ~>
        tuple({0..42,             atom()})

      # ERROR OK
      assert {:error, _} =
        tuple({integer(), integer()}) ~>
        tuple({atom(),    integer()})

      # ERROR MAYBE
      assert {:error, _} =
        tuple({integer(), integer()}) ~>
        tuple({atom(),    0..42})

      # ERROR ERROR
      assert {:error, _} =
        tuple({integer(), integer()}) ~>
        tuple({atom(),    atom()})
    end
  end
end
