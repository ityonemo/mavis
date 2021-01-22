defmodule TypeTest.CompositeBuiltinTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  # basic types.  See https://hexdocs.pm/elixir/typespecs.html#basic-types

  describe "non_neg_integer/0 type" do
    test "works in use" do
      assert %Type.Union{of: [pos_integer(), 0]} == non_neg_integer()
    end
    test "works in matches" do
      assert non_neg_integer() = %Type.Union{of: [pos_integer(), 0]}
    end
  end

  describe "integer/0 type" do
    test "works in use" do
      assert %Type.Union{of: [pos_integer(), 0, neg_integer()]} == integer()
    end
    test "works in matches" do
      assert integer() = %Type.Union{of: [pos_integer(), 0, neg_integer()]}
    end
  end

  describe "map/0 type" do
    test "works in use" do
      assert %Type.Map{optional: %{any() => any()}} == map()
    end
    test "works in matches" do
      assert map() = %Type.Map{optional: %{any() => any()}}
    end
  end

  describe "tuple/0 type" do
    test "works in use" do
      assert %Type.Tuple{elements: [], fixed: false} == tuple()
    end
    test "works in matches" do
      assert tuple() = %Type.Tuple{elements: [], fixed: false}
    end
  end

  # built-in types.  See https://hexdocs.pm/elixir/typespecs.html#built-in-types

  describe "term/0 type" do
    test "works in use" do
      assert any() == term()
    end
    test "works in matches" do
      assert term() = any()
    end
  end

  describe "arity/0 type" do
    test "works in use" do
      assert 0..255 == arity()
    end
    test "works in matches" do
      assert arity() = 0..255
    end
  end

  describe "binary/0 type" do
    test "works in use" do
      assert %Type.Bitstring{size: 0, unit: 8} == binary()
    end
    test "works in matches" do
      assert binary() = %Type.Bitstring{size: 0, unit: 8}
    end
  end

  describe "bitstring/0 type" do
    test "works in use" do
      assert %Type.Bitstring{size: 0, unit: 1} == bitstring()
    end
    test "works in matches" do
      assert bitstring() = %Type.Bitstring{size: 0, unit: 1}
    end
  end

  describe "boolean/0 type" do
    test "works in use" do
      assert Type.union(true, false) == boolean()
    end
    test "works in matches" do
      assert boolean() = Type.union(true, false)
    end
  end

  describe "byte/0 type" do
    test "works in use" do
      assert 0..255 == byte()
    end
    test "works in matches" do
      assert byte() = 0..255
    end
  end

  describe "char/0 type" do
    test "works in use" do
      assert 0..0x10_FFFF == char()
    end
    test "works in matches" do
      assert char() = 0..0x10_FFFF
    end
  end

  describe "charlist/0 type" do
    test "works in use" do
      assert %Type.NonemptyList{type: 0..0x10_FFFF} == charlist()
    end
    test "works in matches" do
      assert charlist() = %Type.NonemptyList{type: 0..0x10_FFFF}
    end
  end

  describe "nonempty_charlist/0 type" do
    test "works in use" do
      assert %Type.NonemptyList{type: 0..0x10_FFFF} == nonempty_charlist()
    end
    test "works in matches" do
      assert nonempty_charlist() = %Type.NonemptyList{type: 0..0x10_FFFF}
    end
  end

  describe "fun/0 type" do
    test "works in use" do
      assert %Type.Function{params: :any, return: any()} == fun()
    end
    test "works in matches" do
      assert fun() = %Type.Function{params: :any, return: any()}
    end
  end

  describe "function/0 type" do
    test "works in use" do
      assert %Type.Function{params: :any, return: any()} == function()
    end
    test "works in matches" do
      assert function() = %Type.Function{params: :any, return: any()}
    end
  end

  describe "identifier/0 type" do
    test "works in use" do
      assert Type.union([reference(), port(), pid()]) == identifier()
    end
    test "works in matches" do
      assert identifier() = Type.union([reference(), port(), pid()])
    end
  end

  describe "iodata/0 type" do
    test "works in use" do
      assert Type.union([iolist(), %Type.Bitstring{size: 0, unit: 8}]) == iodata()
    end
    test "works in matches" do
      assert iodata() = Type.union([iolist(), %Type.Bitstring{size: 0, unit: 8}])
    end
  end

  describe "keyword/0 type" do
    test "works in use" do
      assert %Type.NonemptyList{type: %Type.Tuple{elements: [atom(), any()]}} == keyword()
    end
    test "works in matches" do
      assert keyword() = %Type.NonemptyList{type: %Type.Tuple{elements: [atom(), any()]}}
    end
  end

  describe "list/0 type" do
    test "works in use" do
      assert %Type.NonemptyList{type: any()} == list()
    end
    test "works in matches" do
      assert list() = %Type.NonemptyList{type: any()}
    end
  end

  describe "nonempty_list/0 type" do
    test "works in use" do
      assert %Type.NonemptyList{type: any()} == nonempty_list()
    end
    test "works in matches" do
      assert nonempty_list() = %Type.NonemptyList{type: any()}
    end
  end

  describe "maybe_improper_list/0 type" do
    test "works in use" do
      assert %Type.NonemptyList{type: any(), final: any()} == maybe_improper_list()
    end
    test "works in matches" do
      assert maybe_improper_list() = %Type.NonemptyList{type: any(), final: any()}
    end
  end

  describe "nonempty_maybe_improper_list/0 type" do
    test "works in use" do
      assert %Type.NonemptyList{type: any(), final: any()} == nonempty_maybe_improper_list()
    end
    test "works in matches" do
      assert nonempty_maybe_improper_list() = %Type.NonemptyList{type: any(), final: any()}
    end
  end

  describe "mfa/0 type" do
    test "works in use" do
      assert %Type.Tuple{elements: [module(), atom(), arity()]} == mfa()
    end
    test "works in matches" do
      assert mfa() = %Type.Tuple{elements: [module(), atom(), arity()]}
    end
  end

  describe "no_return/0 type" do
    test "works in use" do
      assert none() == no_return()
    end
    test "works in matches" do
      assert no_return() = none()
    end
  end

  describe "number/0 type" do
    test "works in use" do
      assert Type.union(integer(), float()) == number()
    end
    test "works in matches" do
      assert number() = Type.union(integer(), float())
    end
  end

  describe "struct/0 type" do
    test "works in use" do
      assert %Type.Map{required: %{__struct__: atom()},
                       optional: %{atom() => any()}} == struct()
    end
    test "works in matches" do
      assert struct() =
        %Type.Map{required: %{__struct__: atom()},
                  optional: %{atom() => any()}}
    end
  end

  describe "timeout/0 type" do
    test "works in use" do
      assert Type.union(:infinity, non_neg_integer()) == timeout()
    end
    test "works in matches" do
      assert timeout() = Type.union(:infinity, non_neg_integer())
    end
  end
end
