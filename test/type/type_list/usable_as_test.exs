defmodule TypeTest.TypeList.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.{List, Message}

  describe "the trivial list type" do
    test "is usable as itself and any" do
      assert :ok = builtin(:list) ~> builtin(:list)
      assert :ok = builtin(:list) ~> builtin(:any)
    end

    test "is usable as a union with the list type" do
      assert :ok = builtin(:list) ~> (builtin(:list) <|> builtin(:atom))
    end

    test "is not usable as a union with orthogonal type" do
      assert {:error, _} = builtin(:list) ~> (builtin(:integer) <|> builtin(:atom))
    end

    test "is not usable as any of the other types" do
      targets = TypeTest.Targets.except([builtin(:list)])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: builtin(:list), target: ^target}} =
          (builtin(:list) ~> target)
      end)
    end
  end

  describe "for lists with a specified type" do
    test "it is usable as any list" do
      assert :ok = list(47) ~> list(builtin(:integer))
      assert :ok = list(builtin(:integer)) ~> list(builtin(:any))
    end

    test "it might be usable if the types might be usable" do
      assert {:maybe, _} = list(builtin(:integer)) ~> list(47)
    end

    test "it might be usable as a nonempty list" do
      assert {:maybe, _} = list(builtin(:integer)) ~> list(builtin(:integer), ...)
    end

    test "it might be usable if the types are orthogonal" do
      assert {:maybe, _} = list(builtin(:integer)) ~> list(builtin(:atom))
    end

    test "it won't be usable if the types are orthogonal and the target is nonempty" do
      assert {:error, _} = list(builtin(:integer)) ~> list(builtin(:atom), ...)
    end
  end

  describe "for nonempty: true lists" do
    test "it is usable as similar lists, nonempty or otherwise" do
      assert :ok = list(47, ...) ~> list(builtin(:integer))
      assert :ok = list(builtin(:integer), ...) ~> list(builtin(:integer))

      assert :ok = list(47, ...) ~> list(builtin(:integer), ...)
      assert :ok = list(builtin(:integer), ...) ~> list(builtin(:integer), ...)
    end

    test "it might be usable if the types might be usable" do
      assert {:maybe, _} = list(builtin(:integer), ...) ~> list(47)
      assert {:maybe, _} = list(builtin(:integer), ...) ~> list(47, ...)
    end

    test "if the inner types are hopeless, it won't be usable" do
      assert {:error, _} = list(builtin(:integer), ...) ~> list(builtin(:atom))
      assert {:error, _} = list(builtin(:integer), ...) ~> list(builtin(:atom), ...)
    end
  end

  describe "for lists with 'final' specs" do
    test "it's okay if the final usable" do
      assert :ok = %List{type: builtin(:integer), final: 1} ~>
        %List{type: builtin(:integer), final: builtin(:integer)}
    end

    test "it's maybe if the final is maybe usable" do
      assert {:maybe, _} =
        %List{type: builtin(:integer), final: builtin(:integer)} ~>
          %List{type: builtin(:integer), final: 5}
    end

    test "it's error if the final is not usable" do
      assert {:error, _} =
        %List{type: builtin(:integer), final: builtin(:integer)} ~>
          %List{type: builtin(:integer), final: builtin(:atom)}
    end
  end
end
