defmodule TypeTest.CompositeBuiltinTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  # basic types.  See https://hexdocs.pm/elixir/typespecs.html#basic-types

  describe "map/0 type" do
    test "works in use" do
      assert %Type.Map{optional: %{any() => any()}} == map()
    end
    test "works in matches" do
      assert map() = %Type.Map{optional: %{any() => any()}}
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
      assert %Type.List{type: 0..0x10_FFFF} == charlist()
    end
    test "works in matches" do
      assert charlist() = %Type.List{type: 0..0x10_FFFF}
    end
  end

  describe "nonempty_charlist/0 type" do
    test "works in use" do
      assert %Type.List{type: 0..0x10_FFFF, nonempty: true} == nonempty_charlist()
    end
    test "works in matches" do
      assert nonempty_charlist() = %Type.List{type: 0..0x10_FFFF, nonempty: true}
    end
  end

  describe "fun/0 type" do
    test "works in use" do
      assert %Type.Function{params: :any, return: builtin(:any)} == fun()
    end
    test "works in matches" do
      assert fun() = %Type.Function{params: :any, return: builtin(:any)}
    end
  end

  describe "function/0 type" do
    test "works in use" do
      assert %Type.Function{params: :any, return: builtin(:any)} == function()
    end
    test "works in matches" do
      assert function() = %Type.Function{params: :any, return: builtin(:any)}
    end
  end

  describe "identifier/0 type" do
    test "works in use" do
      assert Type.union([builtin(:reference), builtin(:port), builtin(:pid)]) == builtin(:identifier)
    end
    test "works in matches" do
      assert builtin(:identifier) = Type.union([builtin(:reference), builtin(:port), builtin(:pid)])
    end
  end

  describe "iodata/0 type" do
    test "works in use" do
      assert Type.union([builtin(:iolist), %Type.Bitstring{size: 0, unit: 8}]) == builtin(:iodata)
    end
    test "works in matches" do
      assert builtin(:iodata) = Type.union([builtin(:iolist), %Type.Bitstring{size: 0, unit: 8}])
    end
  end

  describe "keyword/0 type" do
    test "works in use" do
      assert %Type.List{type: %Type.Tuple{elements: [builtin(:atom), builtin(:any)]}} == builtin(:keyword)
    end
    test "works in matches" do
      assert builtin(:keyword) = %Type.List{type: %Type.Tuple{elements: [builtin(:atom), builtin(:any)]}}
    end
  end

  describe "list/0 type" do
    test "works in use" do
      assert %Type.List{type: builtin(:any)} == builtin(:list)
    end
    test "works in matches" do
      assert builtin(:list) = %Type.List{type: builtin(:any)}
    end
  end

  describe "nonempty_list/0 type" do
    test "works in use" do
      assert %Type.List{type: builtin(:any), nonempty: true} == builtin(:nonempty_list)
    end
    test "works in matches" do
      assert builtin(:nonempty_list) = %Type.List{type: builtin(:any), nonempty: true}
    end
  end

  describe "maybe_improper_list/0 type" do
    test "works in use" do
      assert %Type.List{type: builtin(:any), final: builtin(:any)} == builtin(:maybe_improper_list)
    end
    test "works in matches" do
      assert builtin(:maybe_improper_list) = %Type.List{type: builtin(:any), final: builtin(:any)}
    end
  end

  describe "nonempty_maybe_improper_list/0 type" do
    test "works in use" do
      assert %Type.List{type: builtin(:any), nonempty: true, final: builtin(:any)} == builtin(:nonempty_maybe_improper_list)
    end
    test "works in matches" do
      assert builtin(:nonempty_maybe_improper_list) = %Type.List{type: builtin(:any), nonempty: true, final: builtin(:any)}
    end
  end

  describe "mfa/0 type" do
    test "works in use" do
      assert %Type.Tuple{elements: [builtin(:module), builtin(:atom), builtin(:arity)]} == builtin(:mfa)
    end
    test "works in matches" do
      assert builtin(:mfa) = %Type.Tuple{elements: [builtin(:module), builtin(:atom), builtin(:arity)]}
    end
  end

  describe "no_return/0 type" do
    test "works in use" do
      assert builtin(:none) == builtin(:no_return)
    end
    test "works in matches" do
      assert builtin(:no_return) = builtin(:none)
    end
  end

  describe "number/0 type" do
    test "works in use" do
      assert Type.union(builtin(:integer), builtin(:float)) == builtin(:number)
    end
    test "works in matches" do
      assert builtin(:number) = Type.union(builtin(:integer), builtin(:float))
    end
  end

  describe "struct/0 type" do
    test "works in use" do
      assert %Type.Map{required: %{__struct__: builtin(:atom)},
                       optional: %{builtin(:atom) => builtin(:any)}} == builtin(:struct)
    end
    test "works in matches" do
      assert builtin(:struct) =
        %Type.Map{required: %{__struct__: builtin(:atom)},
                  optional: %{builtin(:atom) => builtin(:any)}}
    end
  end

  describe "timeout/0 type" do
    test "works in use" do
      assert Type.union(:infinity, builtin(:non_neg_integer)) == builtin(:timeout)
    end
    test "works in matches" do
      assert builtin(:timeout) = Type.union(:infinity, builtin(:non_neg_integer))
    end
  end
end
