defmodule TypeTest.LiteralFloat.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  describe "literal floats are usable as" do
    test "themselves" do
      assert (47.0 ~> 47.0) == :ok
    end

    test "floats" do
      assert (47.0 ~> float()) == :ok
    end

    test "a union with either itself or float" do
      assert 47.0 ~> (float() <|> :infinity) == :ok
      assert 47.0 ~> (47.0 <|> :infinity) == :ok
    end

    test "any" do
      assert (47.0 ~> any()) == :ok
    end
  end

  alias Type.Message

  describe "literal floats not usable as" do
    test "other literal floats" do
      assert {:error, %Message{type: 47.0, target: 42.0}} =
        (47.0 ~> 42.0)
    end

    test "a corresponding integer" do
      assert {:error, %Message{type: 47.0, target: 47}} =
        (47.0 ~> 47)
    end

    test "a union with a disjoint categories" do
      assert {:error, _} = 47.0 ~> (atom() <|> pid())
    end

    test "any other type" do
      targets = TypeTest.Targets.except([float()])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: 47.0, target: ^target}} =
          (47.0 ~> target)
      end)
    end
  end
end
