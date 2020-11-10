defmodule TypeTest.TypeFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "a parameterized function" do
    test "is bigger than bottom and reference" do
      assert function(( -> builtin(:any))) > builtin(:none)
      assert function(( -> builtin(:any))) > builtin(:reference)
    end

    test "is bigger than a function with a less general return" do
      assert function(( -> builtin(:any))) > function(( -> builtin(:integer)))
    end

    test "is bigger than a function with more parameters" do
      assert function(( -> builtin(:any))) > function((:foo -> builtin(:any)))
      assert function((:foo -> builtin(:any))) > function((:bar, :baz -> builtin(:any)))
    end

    test "is bigger than a function with a less general parameter" do
      assert function((builtin(:any) -> builtin(:any))) >
        function((builtin(:integer) -> builtin(:any)))
      assert function((:foo, builtin(:any) -> builtin(:any))) >
        function((:foo, builtin(:integer) -> builtin(:any)))
    end

    test "is smaller than a function with a more general return" do
      assert function(( -> builtin(:integer))) < function(( -> builtin(:any)))
    end

    test "is smaller than a function with fewer parameters" do
      assert function((:foo -> builtin(:any))) < function(( -> builtin(:any)))
      assert function((:bar, :baz -> builtin(:any))) < function((:foo -> builtin(:any)))
    end

    test "is smaller than a function with a more general parameter" do
      assert function((builtin(:integer) -> builtin(:any))) <
        function((builtin(:any) -> builtin(:any)))
      assert function((:foo, builtin(:integer) -> builtin(:any))) <
        function((:foo, builtin(:any) -> builtin(:any)))
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert function(( -> builtin(:any))) < builtin(:port)
      assert function(( -> builtin(:any))) < builtin(:any)
    end
  end

  describe "a params any function" do
    test "is bigger than bottom and reference" do
      assert function((... -> builtin(:any))) > builtin(:none)
      assert function((... -> builtin(:any))) > builtin(:reference)
    end

    test "is bigger than a function with a less general return" do
      assert function((... -> builtin(:any))) > function((... -> builtin(:integer)))
    end

    test "is smaller than a union containing it" do
      assert function((... -> builtin(:any))) < 0 <|> function((... -> builtin(:any)))
    end

    test "is smaller than a function with a more general return" do
      assert function((... -> builtin(:integer))) < function((... -> builtin(:any)))
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert function((... -> builtin(:any))) < builtin(:port)
      assert function((... -> builtin(:any))) < builtin(:any)
    end
  end

end
