defmodule TypeTest.TypeTuple.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.Message

  @any_tuple builtin(:tuple)

  describe "for the any tuple types" do
    test "you can use it for itself and the builtin any" do
      assert :ok = @any_tuple ~> @any_tuple
      assert :ok = @any_tuple ~> builtin(:any)
    end

    test "you can use it in a union type" do
      assert :ok = @any_tuple ~> (@any_tuple <|> builtin(:atom))
    end

    test "it might be usable as a specified tuple" do
      # zero arity
      assert {:maybe, _} = @any_tuple ~> tuple({})
      # one arity
      assert {:maybe, _} = @any_tuple ~> tuple({:foo})
      # two arity
      assert {:maybe, _} = @any_tuple ~> tuple({builtin(:integer), builtin(:atom)})
    end

    test "you can't use it in a union type of orthogonal types" do
      assert {:error, _} = @any_tuple ~> (builtin(:integer) <|> :infinity)
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
      assert :ok = tuple({builtin(:integer), builtin(:atom)}) ~> @any_tuple
    end

    test "they are usable as tuples with the same length and transitive usable_as" do
      assert :ok = tuple({}) ~> tuple({})
      assert :ok = tuple({:foo}) ~> tuple({:foo})
      assert :ok = tuple({:foo}) ~> tuple({builtin(:atom)})

      assert :ok = tuple({builtin(:integer), builtin(:atom)}) ~>
        tuple({builtin(:integer), builtin(:any)})

      assert :ok = tuple({builtin(:integer), builtin(:atom)}) ~>
        tuple({builtin(:any), builtin(:atom)})
    end

    test "tuple lengths must match" do
      assert {:error, _} = tuple({}) ~> tuple({builtin(:integer)})
      assert {:error, _} = tuple({}) ~> tuple({builtin(:integer), builtin(:any)})

      assert {:error, _} = tuple({builtin(:integer)}) ~> tuple({})
      assert {:error, _} = tuple({builtin(:integer)}) ~> tuple({builtin(:integer), builtin(:any)})

      assert {:error, _} = tuple({builtin(:integer), builtin(:any)}) ~> tuple({})
      assert {:error, _} = tuple({builtin(:integer), builtin(:any)}) ~> tuple({builtin(:integer)})
    end

    test "for a one-tuple it's the expected match of the single element" do
      assert {:maybe, _} = tuple({builtin(:integer)}) ~> tuple({1..10})
      assert {:error, _} = tuple({builtin(:integer)}) ~> tuple({builtin(:atom)})
    end

    test "for a two-tuple it's the ternary logic match of all elements" do
      # OK MAYBE
      assert {:maybe, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({builtin(:integer), 0..42})

      # OK ERROR
      assert {:error, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({builtin(:integer), builtin(:atom)})

      # MAYBE OK
      assert {:maybe, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({0..42,             builtin(:integer)})

      # MAYBE MAYBE
      assert {:maybe, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({0..42,             0..42})

      # MAYBE ERROR
      assert {:error, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({0..42,             builtin(:atom)})

      # ERROR OK
      assert {:error, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({builtin(:atom),    builtin(:integer)})

      # ERROR MAYBE
      assert {:error, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({builtin(:atom),    0..42})

      # ERROR ERROR
      assert {:error, _} =
        tuple({builtin(:integer), builtin(:integer)}) ~>
        tuple({builtin(:atom),    builtin(:atom)})
    end
  end
end
