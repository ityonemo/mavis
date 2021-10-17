defmodule TypeTest.TypeList.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.{List, Message}

  describe "the trivial list type" do
    test "is usable as itself and any" do
      assert :ok = list() ~> list()
      assert :ok = list() ~> any()
    end

    test "is usable as a union with the list type" do
      assert :ok = list() ~> (list() <|> atom())
    end

    test "is not usable as a union with orthogonal type" do
      assert {:error, _} = list() ~> (integer() <|> atom())
    end

    test "is not usable as any of the other types" do
      targets = TypeTest.Targets.except([list(), [], ["foo", "bar"]])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: list(), target: ^target}} =
          (list() ~> target)
      end)
    end
  end

  describe "for lists with a specified type" do
    test "it is usable as any list" do
      assert :ok = list(47) ~> list(integer())
      assert :ok = list(integer()) ~> list(any())
    end

    test "it might be usable if the types might be usable" do
      assert {:maybe, _} = list(integer()) ~> list(47)
    end

    test "it might be usable as a nonempty list" do
      assert {:maybe, _} = list(integer()) ~> list(integer(), ...)
    end

    test "it might be usable if the types are orthogonal" do
      assert {:maybe, _} = list(integer()) ~> list(atom())
    end

    test "it won't be usable if the types are orthogonal and the target is nonempty" do
      assert {:error, _} = list(integer()) ~> list(atom(), ...)
    end
  end

  describe "for nonempty: true lists" do
    test "it is usable as similar lists, nonempty or otherwise" do
      assert :ok = list(47, ...) ~> list(integer())
      assert :ok = list(integer(), ...) ~> list(integer())

      assert :ok = list(47, ...) ~> list(integer(), ...)
      assert :ok = list(integer(), ...) ~> list(integer(), ...)
    end

    test "it might be usable if the types might be usable" do
      assert {:maybe, _} = list(integer(), ...) ~> list(47)
      assert {:maybe, _} = list(integer(), ...) ~> list(47, ...)
    end

    test "if the inner types are hopeless, it won't be usable" do
      assert {:error, _} = list(integer(), ...) ~> list(atom())
      assert {:error, _} = list(integer(), ...) ~> list(atom(), ...)
    end
  end

  describe "for lists with 'final' specs" do
    test "it's okay if the final usable" do
      assert :ok = %List{type: integer(), final: 1} ~>
        %List{type: integer(), final: integer()}
    end

    test "it's maybe if the final is maybe usable" do
      assert {:maybe, _} =
        %List{type: integer(), final: integer()} ~>
          %List{type: integer(), final: 5}
    end

    test "it's error if the final is not usable" do
      assert {:error, _} =
        %List{type: integer(), final: integer()} ~>
          %List{type: integer(), final: atom()}
    end
  end
end
