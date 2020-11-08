defmodule TypeTest do

  # tests on the Type module
  use ExUnit.Case, async: true
  doctest Type

  # tests on types
  doctest Type.Bitstring
  doctest Type.Function
  doctest Type.List
  doctest Type.NoInference
  doctest Type.Tuple
  doctest Type.Map
  doctest Type.Union

  use Type.Operators

  import Type, only: :macros

  describe "Type.group/1 function" do
    test "assigns typegroups correctly" do
      assert 0 == Type.typegroup(builtin(:none))
      assert 1 == Type.typegroup(builtin(:integer))
      assert 1 == Type.typegroup(builtin(:neg_integer))
      assert 1 == Type.typegroup(builtin(:pos_integer))
      assert 1 == Type.typegroup(47)
      assert 1 == Type.typegroup(1..4)
      assert 2 == Type.typegroup(builtin(:float))
      assert 3 == Type.typegroup(builtin(:atom))
      assert 3 == Type.typegroup(:foo)
      assert 4 == Type.typegroup(builtin(:reference))
      assert 5 == Type.typegroup(%Type.Function{params: :any, return: 0})
      assert 6 == Type.typegroup(builtin(:port))
      assert 7 == Type.typegroup(builtin(:pid))
      assert 8 == Type.typegroup(%Type.Tuple{elements: :any})
      assert 9 == Type.typegroup(%Type.Map{})
      assert 10 == Type.typegroup(%Type.List{})
      assert 11 == Type.typegroup(%Type.Bitstring{size: 0, unit: 0})
      assert 12 == Type.typegroup(builtin(:any))
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
      assert builtin(:float) == Type.of(3.14)
    end

    test "assigns atoms correctly" do
      assert :foo == Type.of(:foo)
      assert :bar == Type.of(:bar)
    end

    test "assigns refs correctly" do
      assert builtin(:reference) == Type.of(make_ref())
    end

    test "assigns ports correctly" do
      {:ok, port} = :gen_udp.open(0)
      assert builtin(:port) == Type.of(port)
    end

    test "assigns pids correctly" do
      assert builtin(:pid) == Type.of(self())
    end

    test "assigns tuples correctly" do
      assert %Type.Tuple{elements: []} == Type.of({})
      assert %Type.Tuple{elements: [1]} == Type.of({1})
      assert %Type.Tuple{elements: [:ok, 1]} == Type.of({:ok, 1})
    end

    test "assigns empty list correctly" do
      assert [] == Type.of([])
    end

    test "assigns proper lists correctly, and makes them nonempty" do
      assert %Type.List{type: 1, nonempty: true} == Type.of([1, 1, 1])
      assert %Type.List{type: (1 <|> :foo), nonempty: true} == Type.of([1, :foo, :foo])
      assert %Type.List{type: (1 <|> :foo <|> builtin(:pid)), nonempty: true} == Type.of([self(), 1, :foo])
    end

    test "assigns improper lists correctly" do
      assert %Type.List{type: 1, nonempty: true, final: 1} == Type.of([1, 1 | 1])
    end

    test "assigns maps correctly" do
      assert %Type.Map{} == Type.of(%{})
      assert %Type.Map{required: %{foo: remote(String.t(3))}} ==
        Type.of(%{foo: "foo"})
      assert %Type.Map{required: %{bar: 1, foo: remote(String.t(3))}} ==
        Type.of(%{foo: "foo", bar: 1})
      assert %Type.Map{required: %{1 => remote(String.t(3))}} ==
        Type.of(%{1 => "foo"})

      assert %Type.Map{optional: %{remote(String.t(3)) => remote(String.t(3))}} ==
        Type.of(%{"foo" => "bar"})

      assert %Type.Map{optional: %{remote(String.t(3)) => :bar <|> :quux}} ==
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
      assert %Type.Function{params: [builtin(:any)], return: builtin(:any)} == Type.of(&(&1))
      assert %Type.Function{params: [builtin(:any), builtin(:any)], return: builtin(:any)} == Type.of(&(&1 + &2))
    end

    test "for precompiled lambdas" do
      assert %Type.Function{params: [builtin(:any)], return: builtin(:any)} == Type.of(&TypeTest.LambdaExamples.identity/1)
      assert %Type.Function{params: [builtin(:any)], return: builtin(:any)} == Type.of(TypeTest.LambdaExamples.identity_fn)
    end
  end

  describe "builtins" do
    test "pos_integer"

    test "term" do
      assert builtin(:term) == builtin(:any)
    end

    test "arity" do
      assert 0..255 == builtin(:arity)
    end

    test "binary" do
      assert %Type.Bitstring{unit: 8} == builtin(:binary)
    end

    test "bitstring" do
      assert %Type.Bitstring{unit: 1} == builtin(:bitstring)
    end

    test "boolean" do
      assert true <|> false == builtin(:boolean)
    end

    test "byte" do
      assert 0..255 == builtin(:byte)
    end

    test "char" do
      assert 0..0x10_FFFF == builtin(:char)
    end

    test "charlist" do
      assert %Type.List{type: builtin(:char)} == builtin(:charlist)
    end

    test "nonempty_charlist" do
      assert %Type.List{type: builtin(:char), nonempty: true} ==
        builtin(:nonempty_charlist)
    end

    test "fun" do
      assert %Type.Function{params: :any, return: builtin(:any)} ==
        builtin(:fun)
    end

    test "function" do
      assert %Type.Function{params: :any, return: builtin(:any)} ==
        builtin(:function)
    end

    test "identifier" do
      assert builtin(:pid) <|> builtin(:port) <|> builtin(:reference) ==
        builtin(:identifier)
    end

    test "iolist" do
      assert builtin(:iolist) <|> builtin(:binary) == builtin(:iodata)
    end

    test "keyword" do
      assert %Type.List{type: %Type.Tuple{elements: [builtin(:atom), builtin(:any)]}}
        == builtin(:keyword)
    end

    test "list" do
      assert %Type.List{type: builtin(:any)} == builtin(:list)
    end

    test "nonempty_list" do
      assert %Type.List{type: builtin(:any), nonempty: true} == builtin(:nonempty_list)
    end

    test "maybe_improper_list" do
      assert %Type.List{type: builtin(:any), final: builtin(:any)} ==
        builtin(:maybe_improper_list)
    end

    test "nonempty_maybe_improper_list" do
      assert %Type.List{type: builtin(:any), nonempty: true, final: builtin(:any)} ==
        builtin(:nonempty_maybe_improper_list)
    end

    test "mfa" do
      assert %Type.Tuple{elements: [builtin(:module), builtin(:atom), builtin(:arity)]} ==
        builtin(:mfa)
    end

    test "number" do
      assert builtin(:integer) <|> builtin(:float)
    end

    test "struct"

    test "timeout" do
      assert builtin(:non_neg_integer) <|> :infinity == builtin(:timeout)
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
        %Type.Tuple{elements: [:foo, builtin(:float)]},
        %Type.Tuple{elements: [:bar, builtin(:integer)]}
      ]}} ==
        list(foo: builtin(:float), bar: builtin(:integer))
    end
  end

  describe "function macro" do
    test "works with a zero-arity function" do
      assert %Type.Function{params: [], return: builtin(:any)} ==
        function(( -> builtin(:any)))
    end
  end

  describe "map macro" do
    test "works with a hybrid system" do
      assert %Type.Map{required: %{foo: builtin(:integer)},
                       optional: %{1 => builtin(:integer)}} ==
        map(%{optional(1) => builtin(:integer), foo: builtin(:integer)})
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
