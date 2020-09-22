defmodule TypeTest.TypeList.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]
  use Type.Operators

  alias Type.{List, Message}

  describe "the trivial list type" do
    test "is usable as itself and any" do
      assert :ok = %List{} ~> %List{}
      assert :ok = %List{} ~> builtin(:any)
    end

    test "is not usable as any of the other types" do
      targets = TypeTest.Targets.except([%List{}])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: %List{}, target: ^target}} =
          (%List{} ~> target)
      end)
    end
  end

  describe "for lists with a specified type" do
    test "it is usable as any list" do
      assert :ok = %List{type: 5} ~> %List{type: builtin(:integer)}
      assert :ok = %List{type: builtin(:integer)} ~> %List{type: builtin(:any)}
    end

    test "it might be usable if the types might be usable" do
      assert {:maybe, _} = %List{type: builtin(:integer)} ~> %List{type: 5}
    end

    test "it might be usable as a nonempty list" do
      assert {:maybe, _} = %List{type: builtin(:integer)} ~> %List{type: builtin(:integer), nonempty: true}
    end

    test "it errors if the types are orthogonal" do
      assert {:error, _} = %List{type: builtin(:integer)} ~> %List{type: builtin(:atom)}
    end
  end

  describe "for nonempty: true lists" do
    test "it is usable as similar lists, nonempty or otherwise" do
      assert :ok = %List{type: 5, nonempty: true} ~> %List{type: builtin(:integer)}
      assert :ok = %List{type: builtin(:integer), nonempty: true} ~> %List{type: builtin(:integer)}

      assert :ok = %List{type: 5, nonempty: true} ~> %List{type: builtin(:integer), nonempty: true}
      assert :ok = %List{type: builtin(:integer), nonempty: true} ~> %List{type: builtin(:integer), nonempty: true}
    end

    test "it might be usable if the types might be usable" do
      assert {:maybe, _} = %List{type: builtin(:integer), nonempty: true} ~> %List{type: 5}
      assert {:maybe, _} = %List{type: builtin(:integer), nonempty: true} ~> %List{type: 5, nonempty: true}
    end

    test "if the inner types are hopeless, it won't be usable" do
      assert {:error, _} = %List{type: builtin(:integer), nonempty: true} ~> %List{type: builtin(:atom)}
      assert {:error, _} = %List{type: builtin(:integer), nonempty: true} ~> %List{type: builtin(:atom), nonempty: true}
    end
  end

  describe "for lists with 'final' specs" do
    test "it's okay if the final usable" do
      assert :ok = %List{type: builtin(:integer), final: 1} ~> %List{type: builtin(:integer), final: builtin(:integer)}
    end

    test "it's maybe if the final is maybe usable" do
      assert {:maybe, _} =
        %List{type: builtin(:integer), final: builtin(:integer)} ~> %List{type: builtin(:integer), final: 5}
    end

    test "it's error if the final is not usable" do
      assert {:error, _} =
        %List{type: builtin(:integer), final: builtin(:integer)} ~> %List{type: builtin(:integer), final: builtin(:atom)}
    end
  end
end
