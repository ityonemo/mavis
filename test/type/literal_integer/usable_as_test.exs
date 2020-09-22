defmodule TypeTest.LiteralInteger.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]

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
      assert (47 ~> builtin(:pos_integer)) == :ok
      assert (47 ~> builtin(:non_neg_integer)) == :ok
      assert (0 ~> builtin(:non_neg_integer)) == :ok
      assert (-47 ~> builtin(:neg_integer)) == :ok
      assert (47 ~> builtin(:integer)) == :ok
    end

    test "any" do
      assert (47 ~> builtin(:any)) == :ok
    end
  end

  alias Type.{Bitstring, Function, List, Map, Message, Tuple}

  describe "integers not usable as" do
    test "wrong integer category" do
      assert {:error, %Message{type: 47, target: builtin(:neg_integer)}}
        = (47 ~> builtin(:neg_integer))

      assert {:error, %Message{type: 0, target: builtin(:pos_integer)}}
        = (0 ~> builtin(:pos_integer))
      assert {:error, %Message{type: 0, target: builtin(:neg_integer)}}
        = (0 ~> builtin(:neg_integer))

      assert {:error, %Message{type: -47, target: builtin(:pos_integer)}}
        = (-47 ~> builtin(:pos_integer))
      assert {:error, %Message{type: -47, target: builtin(:non_neg_integer)}}
        = (-47 ~> builtin(:non_neg_integer))
    end

    test "outside their range" do
      assert {:error, %Message{type: 42, target: 47..50}}
        = (42 ~> 47..50)
    end

    test "any other type" do
      targets = TypeTest.Targets.except([builtin(:non_neg_integer), builtin(:pos_integer), builtin(:integer)])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: 42, target: ^target}} =
          (42 ~> target)
      end)
    end
  end

end
