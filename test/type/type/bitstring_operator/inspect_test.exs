defmodule :"Elixir.TypeTest.TypeBitstringOperator.InspectTest" do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.InspectCase

  @moduletag :inspect

  @empty_bitstring type(<<>>)
  @size_bitstring type(<<_::3>>)
  @unit_bitstring type(<<_::_*3>>)
  @size_unit_bitstring type(<<_::3, _::_*3>>)

  describe "the empty bitstring type" do
    test "looks like a itself" do
      assert "type(<<>>)" == inspect(@empty_bitstring)
    end

    test "code translates correctly" do
      assert @empty_bitstring == eval_inspect(@empty_bitstring)
    end
  end

  describe "the size bitstring type" do
    test "looks like a itself" do
      assert "type(<<_::3>>)" == inspect(@size_bitstring)
    end

    test "code translates correctly" do
      assert @size_bitstring == eval_inspect(@size_bitstring)
    end
  end

  describe "the unit bitstring type" do
    test "looks like a itself" do
      assert "type(<<_::_*3>>)" == inspect(@unit_bitstring)
    end

    test "code translates correctly" do
      assert @unit_bitstring == eval_inspect(@unit_bitstring)
    end
  end

  describe "the size_unit bitstring type" do
    test "looks like a itself" do
      assert "type(<<_::3, _::_*3>>)" == inspect(@size_unit_bitstring)
    end

    test "code translates correctly" do
      assert @size_unit_bitstring == eval_inspect(@size_unit_bitstring)
    end
  end
end
