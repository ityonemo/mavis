defmodule TypeTest.LiteralBinary.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  @bitstring "foo"

  describe "literal bitstrings are usable as" do
    test "themselves" do
      assert (literal(@bitstring) ~> literal(@bitstring)) == :ok
    end

    test "bitstrings, binaries, and strings" do
      assert (literal(@bitstring) ~> bitstring()) == :ok
      assert (literal(@bitstring) ~> binary()) == :ok
      assert (literal(@bitstring) ~> remote(String.t())) == :ok
      assert (literal(@bitstring) ~> remote(String.t(3))) == :ok
    end

    test "a union with either itself or binary" do
      assert literal(@bitstring) ~> (binary() <|> :infinity) == :ok
      assert literal(@bitstring) ~> (literal(@bitstring) <|> :infinity) == :ok
    end

    test "any" do
      assert (literal(@bitstring) ~> any()) == :ok
    end
  end

  alias Type.Message

  describe "bitstrings, binaries, and Strings maybe" do
    test "usable as literal bitstrings" do
      assert {:maybe, _} = bitstring() ~> literal(@bitstring)
      assert {:maybe, _} = binary() ~> literal(@bitstring)
      assert {:maybe, _} = remote(String.t()) ~> literal(@bitstring)
      assert {:maybe, _} = remote(String.t(3)) ~> literal(@bitstring)
    end
  end

  describe "literal lists not usable as" do
    test "incorrectly sized binaries or Strings" do
      assert {:error, %Message{type: literal(@bitstring), target: %Bitstring{size: 21}}} =
        (literal(@bitstring) ~> %Bitstring{size: 21})

      assert {:error, %Message{type: literal(@bitstring), target: %Bitstring{unit: 7}}} =
        (literal(@bitstring) ~> %Bitstring{unit: 7})

      assert {:error, %Message{type: literal(@bitstring), target: remote(String.t(4))}} =
        (literal(@bitstring) ~> remote(String.t(4)))
    end

    test "a union with a disjoint categories" do
      assert {:error, _} = literal(@bitstring) ~> (atom() <|> pid())
    end

    test "any other type" do
      targets = TypeTest.Targets.except([binary()])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: literal(@bitstring), target: ^target}} =
          (literal(@bitstring) ~> target)
      end)
    end
  end

  describe "lists not" do
    test "usable as literal lists when types don't match " do
      assert {:error, _} = remote(String.t(4)) ~> literal(@bitstring)
      assert {:error, _} = %Bitstring{size: 21} ~> literal(@bitstring)
      assert {:error, _} = %Bitstring{unit: 7} ~> literal(@bitstring)
    end
  end
end
