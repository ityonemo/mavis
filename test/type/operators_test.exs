defmodule TypeTest.OperatorsTest do
  use ExUnit.Case, async: true
  use Type.Operators

  import Type, only: [builtin: 1]

  @moduletag :operators

  test "~>/2 is the usable_as operator" do
    assert (:foo ~> builtin(:atom)) == :ok
  end

  test "|/2 is the type union operator" do
    assert :foo | :bar == %Type.Union{of: [:bar, :foo]}
  end

  test "ordering operators work as erlang terms" do
    assert 42 < 47
    assert 47 > 42
    assert 42 <= 42
    assert 42 <= 47
    assert 47 >= 47
    assert 47 >= 42

    refute 47 < 42
    refute 42 > 47
    refute 47 <= 42
    refute 42 >= 47
  end

  test "ordering operators prefer term ordering over erlang ordering" do
    refute Kernel.<(builtin(:atom), :foo)
    assert builtin(:atom) < :foo
  end

  test "in/2 is the subtyping operator" do
    assert :bar in :bar
    assert :bar in builtin(:atom)
  end
end
