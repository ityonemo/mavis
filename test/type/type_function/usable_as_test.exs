defmodule TypeTest.TypeFunction.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.Message

  @any builtin(:any)
  @any_fn function((... -> @any))
  @any_atom_fn function((... -> builtin(:atom)))

  test "the any/any function is not usable as any other type" do
    targets = TypeTest.Targets.except([function(( -> 0))])
    Enum.each(targets, fn target ->
      assert {:error, %Message{type: @any_fn, target: ^target}} =
        (@any_fn ~> target)
    end)
  end

  describe "the any/any function" do
    test "is usable as itself and any" do
      assert :ok = @any_fn ~> @any_fn
      assert :ok = @any_fn ~> @any
    end
    test "is maybe usable with an any param'd function" do
      any_integer_fn = function((... -> builtin(:integer)))

      assert {:maybe, [%Message{type: @any_fn, target: ^any_integer_fn}]} =
        @any_fn ~> any_integer_fn
    end

    test "is maybe usable as a top function" do
      assert {:maybe, _} = @any_fn ~> function((_ -> @any))
      assert {:maybe, _} = @any_fn ~> function((_, _ -> @any))
    end

    test "is maybe usable as a generic function" do
      assert {:maybe, _} = @any_fn ~> function((@any -> @any))
      assert {:maybe, _} = @any_fn ~> function((builtin(:integer) -> @any))
    end
  end

  describe "the any/param function" do
    test "is usable if the return types are usable" do
      assert :ok = function((... -> :ok)) ~> @any_atom_fn
      assert :ok = @any_atom_fn ~> @any_atom_fn
      assert :ok = @any_atom_fn ~> @any_fn
    end

    test "is maybe usable if the return types is a subtype" do
      assert {:maybe, [%Message{type: @any_atom_fn,
                                target: function((... -> :ok))}]} =
        @any_atom_fn ~> function((... -> :ok))

      assert {:maybe, _} = @any_atom_fn ~> function((_ -> :ok))
      assert {:maybe, _} = @any_atom_fn ~> function((_, _ -> :ok))
    end

    test "is not usable if the return types don't match" do
      assert {:error, %Message{type: @any_atom_fn,
                               target: function((... -> builtin(:integer)))}} =
        @any_atom_fn ~> function((... -> builtin(:integer)))

      assert {:error, _} = @any_atom_fn ~> function((_ -> builtin(:integer)))
    end
  end

  describe "when you define the type of the parameters" do
    test "the function is usable if the parameters have the same count and the target params are usable of the challenge" do
      # zero arity
      assert :ok = function(( -> :ok)) ~> @any_atom_fn
      assert :ok = function(( -> :ok)) ~> function(( -> :ok))
      assert :ok = function(( -> :ok)) ~> function(( -> builtin(:atom)))

      # one arity
      assert :ok = function((builtin(:atom) -> :ok)) ~> @any_atom_fn
      assert :ok = function((builtin(:atom) -> :ok)) ~> function((builtin(:atom) -> :ok))
      assert :ok = function((builtin(:atom) -> :ok)) ~> function((:ok -> :ok))
      assert :ok = function((builtin(:atom) -> :ok)) ~> function((_ -> :ok))

      # arity two
      assert :ok = function((builtin(:atom), builtin(:integer) -> :ok)) ~> @any_atom_fn
      assert :ok = function((builtin(:atom), builtin(:integer) -> :ok)) ~>
        function((builtin(:atom), builtin(:integer) -> :ok))
      assert :ok = function((builtin(:atom), builtin(:integer) -> :ok)) ~>
        function((:ok, builtin(:integer) -> :ok))
      assert :ok = function((builtin(:atom), builtin(:integer) -> :ok)) ~>
        function((builtin(:atom), 47 -> :ok))
      assert :ok = function((builtin(:atom), builtin(:integer) -> :ok)) ~>
        function((:ok, 47 -> :ok))
      assert :ok = function((builtin(:atom), builtin(:integer) -> :ok)) ~>
        function((_, _ -> :ok))
    end

    test "the function is maybe usable if the return is maybe usable" do
      # zero arity
      assert {:maybe, _} = function(( -> builtin(:atom))) ~> function(( -> :ok))
      # one arity
      assert {:maybe, _} = function((builtin(:atom) -> builtin(:atom))) ~>
        function((builtin(:atom) -> :ok))
      assert {:maybe, _} = function((builtin(:atom) -> builtin(:atom))) ~>
        function((_ -> :ok))
      # two arity
      assert {:maybe, _} = function((builtin(:atom), builtin(:integer) -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> :ok))
      assert {:maybe, _} = function((builtin(:atom), builtin(:integer) -> builtin(:atom))) ~>
        function((_, _ -> :ok))
    end

    test "the function is maybe usable if any of the parameters are maybe usable" do
      # one arity
      assert {:maybe, _} = function((:ok -> builtin(:atom))) ~>
        function((builtin(:atom) -> builtin(:atom)))
      assert {:maybe, _} = function((_ -> builtin(:atom))) ~>
        function((builtin(:atom) -> builtin(:atom)))

      # two arity}
      assert {:maybe, _} = function((:ok, builtin(:integer) -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:atom)))
      assert {:maybe, _} = function((builtin(:atom), 47 -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:atom)))
      assert {:maybe, _} = function((_, _ -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:atom)))
    end

    test "maybes are combined if multiple maybes happen" do
      # one arity
      assert {:maybe, _} = function((:ok -> builtin(:atom))) ~>
        function((builtin(:atom) -> :ok))
      # two arity
      assert {:maybe, _} = function((:ok, builtin(:integer) -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:atom)))
      assert {:maybe, _} = function((builtin(:atom), 47 -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:atom)))
    end

    test "an erroring return is an error" do
      # zero arity
      assert {:error, _} = function(( -> builtin(:atom))) ~>
        function(( -> builtin(:integer)))
      # arity one
      assert {:error, _} = function((builtin(:atom) -> builtin(:atom))) ~>
        function((builtin(:atom) -> builtin(:integer)))
      assert {:error, _} = function((:ok -> builtin(:atom))) ~>
        function((builtin(:atom) -> builtin(:integer)))
      assert {:error, _} = function((:ok -> builtin(:atom))) ~>
        function((_ -> builtin(:integer)))
      # arity two
      assert {:error, _} = function((builtin(:atom), builtin(:integer) -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:integer)))
      assert {:error, _} = function((:ok, builtin(:integer) -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:integer)))
      assert {:error, _} = function((builtin(:atom), 47 -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:integer)))
      assert {:error, _} = function((:ok, 47 -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:integer)))
      assert {:error, _} = function((_, _ -> builtin(:atom))) ~>
        function((builtin(:atom), builtin(:integer) -> builtin(:integer)))
    end

    test "an erroring parameter is an error" do
      # arity one, over ok
      assert {:error, _} = function((builtin(:atom) -> :ok)) ~>
        function((builtin(:integer) -> :ok))
      assert {:error, _} = function((builtin(:atom) -> builtin(:atom))) ~>
        function((builtin(:integer) -> :ok))
      # arity two
      assert {:error, _} = function((builtin(:atom), builtin(:integer) -> :ok)) ~>
        function((builtin(:integer), builtin(:integer) -> :ok))
      assert {:error, _} = function((builtin(:atom), builtin(:integer) -> :ok)) ~>
        function((builtin(:atom), builtin(:atom) -> :ok))
      assert {:error, _} = function((builtin(:atom), 47 -> :ok)) ~>
        function((builtin(:integer), builtin(:integer) -> :ok))
      assert {:error, _} = function((builtin(:atom), builtin(:integer) -> builtin(:atom))) ~>
        function((builtin(:integer), builtin(:integer) -> builtin(:atom)))
    end
  end
end
