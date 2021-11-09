defmodule TypeTest.LiteralBinary.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "literal bitstrings are usable as" do
    test "themselves" do
      assert ("foo" ~> "foo") == :ok
    end

    test "bitstrings, binaries, and strings" do
      assert ("foo" ~> bitstring()) == :ok
      assert ("foo" ~> binary()) == :ok
      assert ("foo" ~> type(String.t())) == :ok
      assert ("foo" ~> type(String.t(3))) == :ok
    end

    test "a union with either itself or binary" do
      assert "foo" ~> (binary() <|> :infinity) == :ok
      assert "foo" ~> ("foo" <|> :infinity) == :ok
    end

    test "any" do
      assert ("foo" ~> any()) == :ok
    end
  end

  alias Type.Message

  describe "bitstrings, binaries, and Strings maybe" do
    test "usable as literal bitstrings" do
      assert {:maybe, _} = bitstring() ~> "foo"
      assert {:maybe, _} = binary() ~> "foo"
      assert {:maybe, _} = type(String.t()) ~> "foo"
      assert {:maybe, _} = type(String.t(3)) ~> "foo"
    end
  end

  describe "literal lists not usable as" do
    test "incorrectly sized binaries or Strings" do
      assert {:error, %Message{type: "foo", target: %Bitstring{size: 21}}} =
        ("foo" ~> %Bitstring{size: 21})

      assert {:error, %Message{type: "foo", target: %Bitstring{unit: 7}}} =
        ("foo" ~> %Bitstring{unit: 7})

      assert {:error, %Message{type: "foo", target: type(String.t(4))}} =
        ("foo" ~> type(String.t(4)))
    end

    test "a union with a disjoint categories" do
      assert {:error, _} = "foo" ~> (atom() <|> pid())
    end

    test "any other type" do
      targets = TypeTest.Targets.except([binary(), "foo"])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: "foo", target: ^target}} =
          ("foo" ~> target)
      end)
    end
  end

  describe "lists not" do
    test "usable as literal lists when types don't match " do
      assert {:error, _} = type(String.t(4)) ~> "foo"
      assert {:error, _} = %Bitstring{size: 21} ~> "foo"
      assert {:error, _} = %Bitstring{unit: 7} ~> "foo"
    end
  end
end
