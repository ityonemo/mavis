defmodule TypeTest do

  # tests on the Type module
  use ExUnit.Case, async: true

  # allows us to use these in doctests
  import Type, only: :macros

  doctest Type

  # tests on types
  doctest Type.Bitstring
  doctest Type.Function
  doctest Type.List
  doctest Type.NoInference
  doctest Type.Tuple
  doctest Type.Map
  doctest Type.Union
  doctest Type.Literal

  use Type.Operators

  test "foo" do
    var_func = function((i -> i when i: integer()))
    assert {:ok, 1..10} == Type.Function.apply_types(var_func, [1..10])
  end

  describe "Type.group/1 function" do
    test "assigns typegroups correctly" do
      assert 0 == Type.typegroup(none())
      assert 1 == Type.typegroup(integer())
      assert 1 == Type.typegroup(neg_integer())
      assert 1 == Type.typegroup(pos_integer())
      assert 1 == Type.typegroup(47)
      assert 1 == Type.typegroup(1..4)
      assert 2 == Type.typegroup(float())
      assert 3 == Type.typegroup(atom())
      assert 3 == Type.typegroup(:foo)
      assert 4 == Type.typegroup(reference())
      assert 5 == Type.typegroup(%Type.Function{params: :any, return: 0})
      assert 6 == Type.typegroup(port())
      assert 7 == Type.typegroup(pid())
      assert 8 == Type.typegroup(%Type.Tuple{elements: :any})
      assert 9 == Type.typegroup(%Type.Map{})
      assert 10 == Type.typegroup(%Type.List{})
      assert 11 == Type.typegroup(%Type.Bitstring{size: 0, unit: 0})
      assert 12 == Type.typegroup(any())
    end
  end

  describe "Type.of/1 function" do
    @describetag :of
    test "assigns integers correctly" do
      assert -47 == Type.of(-47)
      assert 0 == Type.of(0)
      assert 47 == Type.of(47)
    end

    test "assigns floats correctly" do
      assert float() == Type.of(3.14)
    end

    test "assigns atoms correctly" do
      assert :foo == Type.of(:foo)
      assert :bar == Type.of(:bar)
    end

    test "assigns refs correctly" do
      assert reference() == Type.of(make_ref())
    end

    test "assigns ports correctly" do
      {:ok, port} = :gen_udp.open(0)
      assert port() == Type.of(port)
    end

    test "assigns pids correctly" do
      assert pid() == Type.of(self())
    end

    test "assigns tuples correctly" do
      assert tuple({}) == Type.of({})
      assert tuple({1}) == Type.of({1})
      assert tuple({:ok, 1}) == Type.of({:ok, 1})
    end

    test "assigns empty list correctly" do
      assert [] == Type.of([])
    end

    test "assigns proper lists correctly, and makes them nonempty" do
      assert list(1, ...) == Type.of([1, 1, 1])
      assert list((1 <|> :foo), ...) == Type.of([1, :foo, :foo])
      assert list((1 <|> :foo <|> pid()), ...) == Type.of([self(), 1, :foo])
    end

    test "assigns improper lists correctly" do
      assert %Type.List{type: 1, nonempty: true, final: 1} == Type.of([1, 1 | 1])
    end

    test "assigns maps correctly" do
      assert %Type.Map{} == Type.of(%{})
      assert map(%{foo: remote(String.t(3))}) ==
        Type.of(%{foo: "foo"})
      assert map(%{bar: 1, foo: remote(String.t(3))}) ==
        Type.of(%{foo: "foo", bar: 1})
      assert map(%{1 => remote(String.t(3))}) ==
        Type.of(%{1 => "foo"})

      assert map(%{optional(remote(String.t(3))) => remote(String.t(3))}) ==
        Type.of(%{"foo" => "bar"})

      assert map(%{optional(remote(String.t(3))) => :bar <|> :quux}) ==
        Type.of(%{"foo" => :bar, "baz" => :quux})
    end

    test "assigns bitstrings correctly" do
      assert %Type.Bitstring{size: 0, unit: 0} == Type.of("")
      assert %Type.Bitstring{size: 7, unit: 0} == Type.of(<<123::7>>)
      assert remote(String.t(6)) == Type.of("foobar")
      assert remote(String.t(6)) == Type.of("東京")
      assert remote(String.t(8)) == Type.of("🇫🇲")
      assert %Type.Bitstring{size: 56, unit: 0} == Type.of("foobar" <> <<0>>)
      assert %Type.Bitstring{size: 16, unit: 0} == Type.of(<<255, 255>>)
    end
  end

  describe "type.of/1 assigns lambdas" do
    @describetag :of
    test "for a fun that isn't precompiled" do
      assert %Type.Function{params: [any()], return: any()} == Type.of(&(&1))
      assert %Type.Function{params: [any(), any()], return: any()} == Type.of(&(&1 + &2))
    end

    test "for precompiled lambdas" do
      assert %Type.Function{params: [any()], return: any()} == Type.of(&TypeTest.LambdaExamples.identity/1)
      assert %Type.Function{params: [any()], return: any()} == Type.of(TypeTest.LambdaExamples.identity_fn)
    end
  end

  describe "composite builtins" do
    test "non_neg_integer" do
      assert %Type.Union{of: [pos_integer(), 0]}
        == non_neg_integer()
    end

    test "integer" do
      assert %Type.Union{of: [pos_integer(), 0, neg_integer()]}
       == integer()
    end

    test "term" do
      assert term() == any()
    end

    test "arity" do
      assert 0..255 == arity()
    end

    test "binary" do
      assert %Type.Bitstring{unit: 8} == binary()
    end

    test "bitstring" do
      assert %Type.Bitstring{unit: 1} == bitstring()
    end

    test "boolean" do
      assert true <|> false == boolean()
    end

    test "byte" do
      assert 0..255 == byte()
    end

    test "char" do
      assert 0..0x10_FFFF == char()
    end

    test "charlist" do
      assert %Type.List{type: char()} == charlist()
    end

    test "nonempty_charlist" do
      assert %Type.List{type: char(), nonempty: true} ==
        nonempty_charlist()
    end

    test "fun" do
      assert %Type.Function{params: :any, return: any()} ==
        builtin(:fun)
    end

    test "function" do
      assert %Type.Function{params: :any, return: any()} ==
        function()
    end

    test "identifier" do
      assert pid() <|> port() <|> reference() ==
        identifier()
    end

    test "iolist" do
      assert iolist() <|> binary() == iodata()
    end

    test "keyword" do
      assert %Type.List{type: %Type.Tuple{elements: [atom(), any()]}}
        == keyword()
    end

    test "list" do
      assert %Type.List{type: any()} == list()
    end

    test "nonempty_list" do
      assert %Type.List{type: any(), nonempty: true} == nonempty_list()
    end

    test "maybe_improper_list" do
      assert %Type.List{type: any(), final: any()} ==
        maybe_improper_list()
    end

    test "nonempty_maybe_improper_list" do
      assert %Type.List{type: any(), nonempty: true, final: any()} ==
        builtin(:nonempty_maybe_improper_list)
    end

    test "mfa" do
      assert %Type.Tuple{elements: [module(), atom(), arity()]} ==
        mfa()
    end

    test "number" do
      assert integer() <|> float()
    end

    test "struct" do
      assert map(%{
        optional(atom()) => any(),
        __struct__: atom()}) == struct()
    end

    test "timeout" do
      assert non_neg_integer() <|> :infinity == timeout()
    end
  end

  describe "list macro" do
    test "list macro with a single type" do
      assert %Type.List{type: :foo} = list(:foo)
      assert %Type.List{type: %Type.Union{of: [:foo, :bar]}} =
        list(%Type.Union{of: [:foo, :bar]})
    end

    test "list macro with a single ..." do
      assert %Type.List{nonempty: true} = list(...)
    end

    test "list macro with a type and ..." do
      assert %Type.List{type: :foo, nonempty: true} = list(:foo, ...)
      assert %Type.List{type: %Type.Union{of: [:foo, :bar]}, nonempty: true} =
        list(%Type.Union{of: [:foo, :bar]}, ...)
    end

    test "list macro that is a k/v" do
      assert %Type.List{type: %Type.Union{of: [
        tuple({:foo, float()}),
        tuple({:bar, integer()})
      ]}} ==
        list(foo: float(), bar: integer())
    end
  end

  describe "function macro" do
    test "works with a zero-arity function" do
      assert %Type.Function{params: [], return: any()} ==
        function(( -> any()))
    end

    test "works with top-arity functions" do
      assert %Type.Function{params: 1, return: any()} ==
        function((_ -> any()))
      assert %Type.Function{params: 2, return: integer()} ==
        function((_, _ -> integer()))
    end

    test "works with generic var constraints" do
      assert %Type.Function{params: [%Type.Function.Var{name: :i}],
                            return: %Type.Function.Var{name: :i}} ==
        function((i -> i when i: var))
    end
  end

  describe "map macro" do
    test "works with a hybrid system" do
      assert %Type.Map{required: %{foo: integer()},
                       optional: %{1 => integer()}} ==
        map(%{optional(1) => integer(), foo: integer()})
    end
  end

  describe "documentation equivalent test" do
    test "regression" do
      assert TypeTest.TestJson.valid_json?(["47", true])
    end

    test "works" do
      assert TypeTest.TestJson.valid_json?(%{})
      assert TypeTest.TestJson.valid_json?(nil)
      assert TypeTest.TestJson.valid_json?(true)
      assert TypeTest.TestJson.valid_json?(false)
      assert TypeTest.TestJson.valid_json?(47)
      assert TypeTest.TestJson.valid_json?(47.0)
      assert TypeTest.TestJson.valid_json?("47")

      refute TypeTest.TestJson.valid_json?(:foo)

      assert TypeTest.TestJson.valid_json?(["47"])
      assert TypeTest.TestJson.valid_json?(["47", true])

      refute TypeTest.TestJson.valid_json?(["47", :foo])

      assert TypeTest.TestJson.valid_json?(%{"foo" => "bar"})
      assert TypeTest.TestJson.valid_json?(%{"foo" => ["bar", "baz"]})

      refute TypeTest.TestJson.valid_json?(%{foo: "bar"})
      refute TypeTest.TestJson.valid_json?(%{"foo" => ["bar", :baz]})
    end
  end
end
