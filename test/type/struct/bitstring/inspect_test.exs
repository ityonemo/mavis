defmodule TypeTest.Bitstring.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  pull_types(defmodule Bitstrings do
    @type empty_bitstring :: <<>>
    @type any_bitstring :: <<_::_*1>>
    @type fixed_bitstring :: <<_::47>>
    @type any_binary :: <<_::_*8>>
    @type multi_bitstring :: <<_::_*16>>
    @type compound_bitstring :: <<_::16, _::_*8>>
  end)

  describe "the empty bitstring type" do
    test "looks like itself" do
      assert ~s(<<_::0>>) == inspect(@empty_bitstring)
    end

    test "code translates correctly" do
      assert @empty_bitstring == eval_inspect(@empty_bitstring)
    end
  end

  describe "the bitstring type" do
    test "looks like bitstring" do
      assert "bitstring()" == inspect(@any_bitstring)
    end

    test "code translates correctly" do
      assert @any_bitstring == eval_inspect(@any_bitstring)
    end
  end

  describe "the fixed bitstring type" do
    test "is wrapped in `type`" do
      assert "type(<<_::47>>)" == inspect(@fixed_bitstring)
    end

    test "code translates correctly" do
      assert @fixed_bitstring == eval_inspect(@fixed_bitstring)
    end
  end

  describe "the binary type" do
    test "looks like bitstring" do
      assert "binary()" == inspect(@any_binary)
    end

    test "code translates correctly" do
      assert @any_binary == eval_inspect(@any_binary)
    end
  end

  describe "the multi bitstring type" do
    test "is wrapped in `type`" do
      assert "type(<<_::8, _::_*16>>)" == inspect(@multi_bitstring)
    end

    test "code translates correctly" do
      assert @multi_bitstring == eval_inspect(@multi_bitstring)
    end
  end

  describe "the compound bitstring type" do
    test "is wrapped in `type`" do
      assert "type(<<_::_*16>>)" == inspect(@compound_bitstring)
    end

    test "code translates correctly" do
      assert @compound_bitstring == eval_inspect(@compound_bitstring)
    end
  end
end
