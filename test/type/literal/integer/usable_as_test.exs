defmodule TypeTest.LiteralInteger.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  describe "integers are usable as" do
    test "themselves" do
      assert (47 ~> 47) == :ok
    end

    test "integers in their range" do
      assert (47 ~> 47..52) == :ok
      assert (47 ~> 45..52) == :ok
      assert (47 ~> -52..52) == :ok
    end

    test "integer category" do
      assert (47 ~> pos_integer()) == :ok
      assert (47 ~> non_neg_integer()) == :ok
      assert (0 ~> non_neg_integer()) == :ok
      assert (-47 ~> neg_integer()) == :ok
      assert (47 ~> integer()) == :ok
    end

    test "a union with the appropriate category" do
      assert 47 ~> (pos_integer() <|> :infinity) == :ok
      assert 47 ~> (non_neg_integer() <|> :infinity) == :ok
      assert 47 ~> (integer() <|> :infinity) == :ok
    end

    test "any" do
      assert (47 ~> any()) == :ok
    end
  end

  alias Type.Message

  describe "integers not usable as" do
    test "wrong integer category" do
      assert {:error, %Message{challenge: 47, target: neg_integer()}}
        = (47 ~> neg_integer())

      assert {:error, %Message{challenge: 0, target: pos_integer()}}
        = (0 ~> pos_integer())
      assert {:error, %Message{challenge: 0, target: neg_integer()}}
        = (0 ~> neg_integer())

      assert {:error, %Message{challenge: -47, target: pos_integer()}}
        = (-47 ~> pos_integer())
      assert {:error, %Message{challenge: -47, target: non_neg_integer()}}
        = (-47 ~> non_neg_integer())
    end

    test "outside their range" do
      assert {:error, %Message{challenge: 42, target: 47..50}}
        = (42 ~> 47..50)
    end

    test "a union with the noninclusive categories" do
      assert {:error, _} = -47 ~> (pos_integer() <|> :infinity)
    end

    test "any other type" do
      targets = TypeTest.Targets.except([non_neg_integer(), pos_integer(), integer()])
      Enum.each(targets, fn target ->
        assert {:error, %Message{challenge: 42, target: ^target}} =
          (42 ~> target)
      end)
    end
  end

end
