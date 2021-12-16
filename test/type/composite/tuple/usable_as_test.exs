defmodule TypeTest.TypeTuple.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.Message

  @any_tuple tuple()
  @min_2_tuple type({any(), any(), ...})
  @min_3_tuple type({any(), any(), any(), ...})

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
      assert {:maybe, _} = @any_tuple ~> type({})
      # one arity
      assert {:maybe, _} = @any_tuple ~> type({:foo})
      # two arity
      assert {:maybe, _} = @any_tuple ~> type({integer(), atom()})
      assert {:maybe, _} = @min_2_tuple ~> type({:ok, integer()})
    end

    test "you can maybe use it as a more restrictive tuple" do
      assert {:maybe, _} = @any_tuple ~> @min_2_tuple
    end

    test "you can't use it in a union type of orthogonal types" do
      assert {:error, _} = @any_tuple ~> (integer() <|> :infinity)
    end

    test "you can't use it as a tuple that's too small" do
      assert {:error, _} = @min_3_tuple ~> type({:ok, binary()})
    end

    test "you can't use it for anything else" do
      targets = TypeTest.Targets.except([type({})])
      Enum.each(targets, fn target ->
        assert {:error, %Message{challenge: @any_tuple, target: ^target}} =
          (@any_tuple ~> target)
      end)
    end
  end

  describe "for specified tuples" do
    test "they are usable as any tuple" do
      assert :ok = type({}) ~> @any_tuple
      assert :ok = type({:foo}) ~> @any_tuple
      assert :ok = type({integer(), atom()}) ~> @any_tuple
    end

    test "they are usable as mininum arity tuples" do
      assert :ok = type({:ok, integer()}) ~> @min_2_tuple
      assert :ok = type({:ok, binary(), integer()}) ~> @min_2_tuple
    end

    test "they are usable as tuples with the same length and transitive usable_as" do
      assert :ok = type({}) ~> type({})
      assert :ok = type({:foo}) ~> type({:foo})
      assert :ok = type({:foo}) ~> type({atom()})

      assert :ok = type({integer(), atom()}) ~>
        type({integer(), any()})

      assert :ok = type({integer(), atom()}) ~>
        type({any(), atom()})
    end

    test "tuple lengths must match" do
      assert {:error, _} = type({}) ~> type({integer()})
      assert {:error, _} = type({}) ~> type({integer(), any()})

      assert {:error, _} = type({integer()}) ~> type({})
      assert {:error, _} = type({integer()}) ~> type({integer(), any()})

      assert {:error, _} = type({integer(), any()}) ~> type({})
      assert {:error, _} = type({integer(), any()}) ~> type({integer()})
    end

    test "for a one-tuple it's the expected match of the single element" do
      assert {:maybe, _} = type({integer()}) ~> type({1..10})
      assert {:error, _} = type({integer()}) ~> type({atom()})
    end

    test "you can't use it as a tuple for which it doesn't have enough" do
      assert {:error, _} = type({:ok, integer()}) ~> @min_3_tuple
    end

    test "for a two-tuple it's the ternary logic match of all elements" do
      # OK MAYBE
      assert {:maybe, _} =
        type({integer(), integer()}) ~>
        type({integer(), 0..42})

      # OK ERROR
      assert {:error, _} =
        type({integer(), integer()}) ~>
        type({integer(), atom()})

      # MAYBE OK
      assert {:maybe, _} =
        type({integer(), integer()}) ~>
        type({0..42,             integer()})

      # MAYBE MAYBE
      assert {:maybe, _} =
        type({integer(), integer()}) ~>
        type({0..42,             0..42})

      # MAYBE ERROR
      assert {:error, _} =
        type({integer(), integer()}) ~>
        type({0..42,             atom()})

      # ERROR OK
      assert {:error, _} =
        type({integer(), integer()}) ~>
        type({atom(),    integer()})

      # ERROR MAYBE
      assert {:error, _} =
        type({integer(), integer()}) ~>
        type({atom(),    0..42})

      # ERROR ERROR
      assert {:error, _} =
        type({integer(), integer()}) ~>
        type({atom(),    atom()})
    end
  end
end
