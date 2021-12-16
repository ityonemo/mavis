defmodule TypeTest.TypeFunction.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as
  @moduletag :function

  import Type, only: :macros
  use Type.Operators

  alias Type.{Function, Message}

  @any_fn type((... -> any()))
  @any_atom_fn type((... -> atom()))

  test "the any/any function is not usable as any other type" do
    targets = TypeTest.Targets.except([type(( -> 0))])
    Enum.each(targets, fn target ->
      assert {:error, %Message{challenge: @any_fn, target: ^target}} =
        (@any_fn ~> target)
    end)
  end

  describe "the any/any function" do
    test "is usable as itself and any" do
      assert :ok = @any_fn ~> @any_fn
      assert :ok = @any_fn ~> any()
    end

    test "is maybe usable with an any param'd function" do
      any_integer_fn = type((... -> integer()))

      assert {:maybe, [%Message{challenge: @any_fn, target: ^any_integer_fn}]} =
        @any_fn ~> any_integer_fn
    end
  end

  describe "the any/param function" do
    test "is usable if the return types are usable" do
      assert :ok = type((... -> :ok)) ~> @any_atom_fn
      assert :ok = @any_atom_fn ~> @any_atom_fn
      assert :ok = @any_atom_fn ~> @any_fn
    end

    test "is maybe usable if the return types is a subtype" do
      assert {:maybe, [%Message{challenge: @any_atom_fn,
                                target: type((... -> :ok))}]} =
        @any_atom_fn ~> type((... -> :ok))
    end

    test "is not usable if the return types don't match" do
      assert {:error, %Message{challenge: @any_atom_fn,
                               target: type((... -> integer()))}} =
        @any_atom_fn ~> type((... -> integer()))
    end
  end

  describe "when you define the type of the parameters" do
    test "the function is usable if the parameters have the same count and the target params are usable of the challenge" do
      # zero arity
      assert :ok = type(( -> :ok)) ~> @any_atom_fn
      assert :ok = type(( -> :ok)) ~> type(( -> :ok))
      assert :ok = type(( -> :ok)) ~> type(( -> atom()))

      # arity one
      assert :ok = type((atom() -> :ok)) ~> @any_atom_fn
      assert :ok = type((atom() -> :ok)) ~> type((atom() -> :ok))
      assert :ok = type((atom() -> :ok)) ~> type((:ok -> :ok))

      # arity two
      assert :ok = type((atom(), integer() -> :ok)) ~> @any_atom_fn
      assert :ok = type((atom(), integer() -> :ok)) ~> type((atom(), integer() -> :ok))
      assert :ok = type((atom(), integer() -> :ok)) ~> type((:ok, integer() -> :ok))
      assert :ok = type((atom(), integer() -> :ok)) ~> type((atom(), 47 -> :ok))
      assert :ok = type((atom(), integer() -> :ok)) ~> type((:ok, 47 -> :ok))
    end

    test "the function is maybe usable if the return is maybe usable" do
      # zero arity
      assert {:maybe, _} = type(( -> atom())) ~> type(( -> :ok))
      # one arity
      assert {:maybe, _} = type((atom() -> atom())) ~> type((atom() -> :ok))
      # two arity
      assert {:maybe, _} = type((atom(), integer() -> atom())) ~> type((atom(), integer() -> :ok))
    end

    test "the function is maybe usable if any of the parameters are maybe usable" do
      # one arity
      assert {:maybe, _} = type((:ok -> atom())) ~> type((atom() -> atom()))

      # two arity
      assert {:maybe, _} = type((:ok, integer() -> atom())) ~> type((atom(), integer() -> atom()))
      assert {:maybe, _} = type((atom(), 47 -> atom())) ~> type((atom(), integer() -> atom()))
    end

    test "maybes are combined if multiple maybes happen" do
      # one arity
      assert {:maybe, _} = type((:ok -> atom())) ~> type((atom() -> :ok))
      # two arity
      assert {:maybe, _} = type((:ok, integer() -> atom())) ~> type((atom(), integer() -> atom()))
      assert {:maybe, _} = type((atom(), 47 -> atom())) ~> type((atom(), integer() -> atom()))
    end

    test "an erroring return is an error" do
      # zero arity
      assert {:error, _} = type(( -> atom())) ~> type(( -> integer()))
      # arity one
      assert {:error, _} = type((atom() -> atom()) )~> type((atom() -> integer()))
      assert {:error, _} = type((:ok -> atom())) ~> type((atom() -> integer()))
      # arity two
      assert {:error, _} = type((atom(), integer() -> atom())) ~> type((atom(), integer() -> integer()))
      assert {:error, _} = type((:ok, integer() -> atom())) ~> type((atom(), integer() -> integer()))
      assert {:error, _} = type((atom(), 47 -> atom())) ~> type((atom(), integer() -> integer()))
      assert {:error, _} = type((:ok, 47 -> atom())) ~> type((atom(), integer() -> integer()))
    end

    test "an erroring parameter is an error" do
      # arity one, over ok
      assert {:error, _} = type((atom() -> :ok)) ~> type((integer() -> :ok))
      assert {:error, _} = type((atom() -> atom())) ~> type((integer() -> :ok))
      # arity two
      assert {:error, _} = type((atom(), integer() -> :ok)) ~> type((integer(), integer() -> :ok))
      assert {:error, _} = type((atom(), integer() -> :ok)) ~> type((atom(), atom() -> :ok))
      assert {:error, _} = type((atom(), 47 -> :ok)) ~> type((integer(), integer() -> :ok))
      assert {:error, _} = type((atom(), integer() -> atom())) ~> type((integer(), integer() -> atom()))
    end
  end
end
