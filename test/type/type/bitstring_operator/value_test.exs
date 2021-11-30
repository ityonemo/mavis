defmodule TypeTest.TypeBitstringOperator.ValueTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.InspectCase

  alias Type.Bitstring

  @moduletag :inspect

  # NOTE that the zero empty bitstring is unicode: true.  Why?
  # iex> String.valid("") #==> true
  @empty_bitstring %Bitstring{unit: 0, size: 0, unicode: true}
  @size_bitstring %Bitstring{unit: 0, size: 3, unicode: false}
  @unit_bitstring %Bitstring{unit: 3, size: 0, unicode: false}
  @size_unit_bitstring %Bitstring{unit: 3, size: 3, unicode: false}

  describe "empty bitstring" do
    test "evals" do
      assert @empty_bitstring == type(<<>>)
      assert @empty_bitstring == type(<<_::0>>)
      assert @empty_bitstring == type(<<_::_*0>>)
      assert @empty_bitstring == type(<<_::0, _::_*0>>)
    end

    test "matches" do
      zero = 0

      assert type(<<>>) = @empty_bitstring

      assert type(<<_::0>>) = @empty_bitstring
      assert type(<<_::^zero>>) = @empty_bitstring
      assert type(<<_::sz1>>) = @empty_bitstring

      assert type(<<_::_*0>>) = @empty_bitstring
      assert type(<<_::_*^zero>>) = @empty_bitstring
      assert type(<<_::_*un1>>) = @empty_bitstring

      assert type(<<_::0, _::_*0>>) = @empty_bitstring
      assert type(<<_::^zero, _::_*^zero>>) = @empty_bitstring
      assert type(<<_::sz2, _::_*un2>>) = @empty_bitstring

      assert Enum.all?([sz1, sz2, un1, un2], &(&1 == 0))
    end
  end

  describe "size bitstring" do
    test "evals" do
      assert @size_bitstring == type(<<_::3>>)
      assert @size_bitstring == type(<<_::3, _::_*0>>)
    end

    test "matches" do
      zero = 0
      three = 3

      refute match?(type(<<>>), @size_bitstring)

      assert type(<<_::3>>) = @size_bitstring
      assert type(<<_::^three>>) = @size_bitstring

      refute match?(type(<<_::_*_any>>), @size_bitstring)

      assert type(<<_::3, _::_*0>>) = @size_bitstring
      assert type(<<_::^three, _::_*^zero>>) = @size_bitstring
    end
  end

  describe "unit bitstring" do
    test "evals" do
      assert @unit_bitstring == type(<<_::_*3>>)
      assert @unit_bitstring == type(<<_::0, _::_*3>>)
    end

    test "matches" do
      zero = 0
      three = 3

      refute match?(type(<<>>), @unit_bitstring)

      refute match?(type(<<_::_any>>), @unit_bitstring)

      assert type(<<_::_*3>>) = @unit_bitstring
      assert type(<<_::_*^three>>) = @unit_bitstring

      assert type(<<_::0, _::_*3>>) = @unit_bitstring
      assert type(<<_::^zero, _::_*^three>>) = @unit_bitstring
    end
  end

  describe "size_unit bitstring" do
    test "evals" do
      assert @size_unit_bitstring == type(<<_::3, _::_*3>>)
    end

    test "matches" do
      three = 3
      refute match?(type(<<>>), @size_unit_bistring)

      refute match?(type(<<_::_any>>), @size_unit_bitstring)

      refute match?(type(<<_::_*_any>>), @size_unit_bitstring)

      assert type(<<_::3, _::_*3>>) = @size_unit_bitstring
      assert type(<<_::^three, _::_*^three>>) = @size_unit_bitstring
    end
  end
end
