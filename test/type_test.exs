defmodule TypeTest do

  # tests on the Type module
  use ExUnit.Case, async: true

  import Type, only: [builtin: 1]

  @moduletag :root

  #describe "the Type.collect/1 function" do
  #  test "gives :type_ok when all types are ok" do
  #    assert :type_ok == Type.collect([:type_ok])
  #    assert :type_ok == Type.collect([:type_ok, :type_ok, :type_ok])
  #  end
#
  #  test "gives :type_maybe if all are ok except for maybes" do
  #    assert :type_maybe == Type.collect([:type_ok, :type_ok, :type_maybe])
  #    assert :type_maybe == Type.collect([:type_ok, :type_maybe, :type_maybe])
  #    assert :type_maybe == Type.collect([:type_maybe])
  #    assert :type_maybe == Type.collect([:type_maybe, :type_maybe])
  #  end
#
  #  test "gives :type_error if any type is in error" do
  #    assert :type_error == Type.collect([:type_ok, :type_maybe, :type_error])
  #    assert :type_error == Type.collect([:type_error, :type_ok, :type_ok])
  #    assert :type_error == Type.collect([:type_error, :type_error])
  #  end
  #end

  describe "Type.group/1 function" do
    test "assigns typegroups correctly" do
      assert 0 == Type.typegroup(builtin(:any))
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
      assert 12 == Type.typegroup(builtin(:none))
    end
  end
end
