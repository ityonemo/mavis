defmodule TypeTest do

  # tests on the Type module
  use ExUnit.Case, async: true

  use Type.Operators

  import Type, only: [builtin: 1, remote: 1]

  describe "Type.group/1 function" do
    test "assigns typegroups correctly" do
      assert 0 == Type.typegroup(builtin(:none))
      assert 1 == Type.typegroup(builtin(:integer))
      assert 1 == Type.typegroup(builtin(:neg_integer))
      assert 1 == Type.typegroup(builtin(:non_neg_integer))
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
      assert %Type.List{type: (1 | :foo), nonempty: true} == Type.of([1, :foo, :foo])
      assert %Type.List{type: (1 | :foo | builtin(:pid)), nonempty: true} == Type.of([self(), 1, :foo])
    end

    test "assigns improper lists correctly" do
      assert %Type.List{type: 1, nonempty: true, final: 1} == Type.of([1, 1 | 1])
    end

    test "assigns maps correctly" do
      assert %Type.Map{} == Type.of(%{})
      assert %Type.Map{required: %{foo: remote(String.t)}} ==
        Type.of(%{foo: "foo"})
      assert %Type.Map{required: %{bar: 1, foo: remote(String.t)}} ==
        Type.of(%{foo: "foo", bar: 1})
      assert %Type.Map{required: %{1 => remote(String.t)}} ==
        Type.of(%{1 => "foo"})

      assert %Type.Map{optional: %{remote(String.t) => remote(String.t)}} ==
        Type.of(%{"foo" => "bar"})
    end

    test "assigns bitstrings correctly" do
      assert %Type.Bitstring{size: 0, unit: 0} == Type.of("")
      assert %Type.Bitstring{size: 7, unit: 0} == Type.of(<<123::7>>)
      assert remote(String.t) == Type.of("foobar")
      assert remote(String.t) == Type.of("東京")
      assert remote(String.t) == Type.of("🇫🇲")
      assert %Type.Bitstring{size: 56, unit: 0} == Type.of("foobar" <> <<0>>)
      assert %Type.Bitstring{size: 16, unit: 0} == Type.of(<<255, 255>>)
    end
  end

  describe "type.of/1 assigns lambdas" do
    @describetag :of
    test "for a fun that isn't precompiled" do
      assert %Type.Function{params: [builtin(:any)], return: builtin(:any), inferred: false} == Type.of(&(&1))
    end

    test "for precompiled lambdas" do
      assert %Type.Function{params: [builtin(:any)], return: builtin(:any)} == Type.of(&TypeTest.LambdaExamples.identity/1)
      assert %Type.Function{params: [builtin(:any)], return: builtin(:any)} == Type.of(TypeTest.LambdaExamples.identity_fn)
    end

    test "a lambda with a move" do
      assert Type.Function.has_opcode?({TypeTest.LambdaExamples, :with_move, 2}, [:move])
      assert %Type.Function{params: [builtin(:any), builtin(:any)], return: builtin(:any)} == Type.of(&TypeTest.LambdaExamples.with_move/2)
    end

    test "a lambda that sets a value" do
      assert %Type.Function{params: [], return: 47} == Type.of(&TypeTest.LambdaExamples.forty_seven/0)
      assert %Type.Function{params: [], return: remote(String.t)} == Type.of(&TypeTest.LambdaExamples.forty_seven_str/0)
    end

    test "a lambda with a backpropagating function" do
      assert Type.Function.has_opcode?({TypeTest.LambdaExamples, :with_bitsize, 1}, [:gc_bif, :bit_size])
      assert %Type.Function{params: [%Type.Bitstring{size: 0, unit: 1}], return: builtin(:non_neg_integer)} == Type.of(&TypeTest.LambdaExamples.with_bitsize/1)
    end

    #test "a lambda with a real function" do
    #  assert Type.Function.has_opcode?({TypeTest.LambdaExamples, :with_add, 2}, [:gc_bif, :+])
    #  assert %Type.Function{params: [builtin(:any), builtin(:any)], return: builtin(:any)} == Type.of(&TypeTest.LambdaExamples.with_add/2)
    #end
  end
end
