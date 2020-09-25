defmodule TypeTest.TypeFunction.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]
  use Type.Operators

  alias Type.{Function, Message}

  @any %Type{name: :any}
  @any_fn %Function{params: :any, return: @any}
  @any_atom_fn %Function{params: :any, return: builtin(:atom)}

  test "the any/any function is not usable as any other type" do
    targets = TypeTest.Targets.except([%Type.Function{params: [], return: 0}])
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
      any_integer_fn = %Function{params: :any, return: builtin(:integer)}

      assert {:maybe, [%Message{type: @any_fn, target: ^any_integer_fn}]} =
        @any_fn ~> any_integer_fn
    end
  end

  describe "the any/param function" do
    test "is usable if the return types are usable" do
      assert :ok = %Function{params: :any, return: :ok} ~> @any_atom_fn
      assert :ok = @any_atom_fn ~> @any_atom_fn
      assert :ok = @any_atom_fn ~> @any_fn
    end

    test "is maybe usable if the return types is a subtype" do
      assert {:maybe, [%Message{type: @any_atom_fn,
                                target: %Function{params: :any, return: :ok}}]} =
        @any_atom_fn ~> %Function{params: :any, return: :ok}
    end

    test "is not usable if the return types don't match" do
      assert {:error, %Message{type: @any_atom_fn,
                               target: %Function{params: :any, return: builtin(:integer)}}} =
        @any_atom_fn ~> %Function{params: :any, return: builtin(:integer)}
    end
  end

  describe "when you define the type of the parameters" do
    test "the function is usable if the parameters have the same count and the target params are usable of the challenge" do
      # zero arity
      assert :ok = %Function{params: [], return: :ok} ~> @any_atom_fn
      assert :ok = %Function{params: [], return: :ok} ~> %Function{params: [], return: :ok}
      assert :ok = %Function{params: [], return: :ok} ~> %Function{params: [], return: builtin(:atom)}

      # arity one
      assert :ok = %Function{params: [builtin(:atom)], return: :ok} ~> @any_atom_fn
      assert :ok = %Function{params: [builtin(:atom)], return: :ok} ~> %Function{params: [builtin(:atom)], return: :ok}
      assert :ok = %Function{params: [builtin(:atom)], return: :ok} ~> %Function{params: [:ok], return: :ok}

      # arity two
      assert :ok = %Function{params: [builtin(:atom), builtin(:integer)], return: :ok} ~> @any_atom_fn
      assert :ok = %Function{params: [builtin(:atom), builtin(:integer)], return: :ok} ~> %Function{params: [builtin(:atom), builtin(:integer)], return: :ok}
      assert :ok = %Function{params: [builtin(:atom), builtin(:integer)], return: :ok} ~> %Function{params: [:ok, builtin(:integer)], return: :ok}
      assert :ok = %Function{params: [builtin(:atom), builtin(:integer)], return: :ok} ~> %Function{params: [builtin(:atom), 47], return: :ok}
      assert :ok = %Function{params: [builtin(:atom), builtin(:integer)], return: :ok} ~> %Function{params: [:ok, 47], return: :ok}
    end

    test "the function is maybe usable if the return is maybe usable" do
      # zero arity
      assert {:maybe, _} = %Function{params: [], return: builtin(:atom)} ~> %Function{params: [], return: :ok}
      # one arity
      assert {:maybe, _} = %Function{params: [builtin(:atom)], return: builtin(:atom)} ~> %Function{params: [builtin(:atom)], return: :ok}
      # two arity
      assert {:maybe, _} = %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:atom)} ~> %Function{params: [builtin(:atom), builtin(:integer)], return: :ok}
    end

    test "the function is maybe usable if any of the parameters are maybe usable" do
      # one arity
      assert {:maybe, _} = %Function{params: [:ok], return: builtin(:atom)} ~> %Function{params: [builtin(:atom)], return: builtin(:atom)}
      # two arity}
      assert {:maybe, _} = %Function{params: [:ok, builtin(:integer)], return: builtin(:atom)} ~> %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:atom)}
      assert {:maybe, _} = %Function{params: [builtin(:atom), 47], return: builtin(:atom)} ~> %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:atom)}
    end

    test "maybes are combined if multiple maybes happen" do
      # one arity
      assert {:maybe, _} = %Function{params: [:ok], return: builtin(:atom)} ~> %Function{params: [builtin(:atom)], return: :ok}
      # two arity
      assert {:maybe, _} = %Function{params: [:ok, builtin(:integer)], return: builtin(:atom)} ~> %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:atom)}
      assert {:maybe, _} = %Function{params: [builtin(:atom), 47], return: builtin(:atom)} ~> %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:atom)}
    end

    test "an erroring return is an error" do
      # zero arity
      assert {:error, _} = %Function{params: [], return: builtin(:atom)} ~> %Function{params: [], return: builtin(:integer)}
      # arity one
      assert {:error, _} = %Function{params: [builtin(:atom)], return: builtin(:atom)} ~> %Function{params: [builtin(:atom)], return: builtin(:integer)}
      assert {:error, _} = %Function{params: [:ok], return: builtin(:atom)} ~> %Function{params: [builtin(:atom)], return: builtin(:integer)}
      # arity two
      assert {:error, _} = %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:atom)} ~>
        %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:integer)}
      assert {:error, _} = %Function{params: [:ok, builtin(:integer)], return: builtin(:atom)} ~>
        %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:integer)}
      assert {:error, _} = %Function{params: [builtin(:atom), 47], return: builtin(:atom)} ~>
        %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:integer)}
      assert {:error, _} = %Function{params: [:ok, 47], return: builtin(:atom)} ~>
        %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:integer)}
    end

    test "an erroring parameter is an error" do
      # arity one, over ok
      assert {:error, _} = %Function{params: [builtin(:atom)], return: :ok} ~> %Function{params: [builtin(:integer)], return: :ok}
      assert {:error, _} = %Function{params: [builtin(:atom)], return: builtin(:atom)} ~> %Function{params: [builtin(:integer)], return: :ok}
      # arity two
      assert {:error, _} = %Function{params: [builtin(:atom), builtin(:integer)], return: :ok} ~>
        %Function{params: [builtin(:integer), builtin(:integer)], return: :ok}
      assert {:error, _} = %Function{params: [builtin(:atom), builtin(:integer)], return: :ok} ~>
        %Function{params: [builtin(:atom), builtin(:atom)], return: :ok}
      assert {:error, _} = %Function{params: [builtin(:atom), 47], return: :ok} ~>
        %Function{params: [builtin(:integer), builtin(:integer)], return: :ok}
      assert {:error, _} = %Function{params: [builtin(:atom), builtin(:integer)], return: builtin(:atom)} ~>
        %Function{params: [builtin(:integer), builtin(:integer)], return: builtin(:atom)}
    end
  end
end
