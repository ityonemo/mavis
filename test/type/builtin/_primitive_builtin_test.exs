defmodule TypeTest.PrimitiveBuiltinTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  describe "any/0 type" do
    test "works in use" do
      assert %Type{name: :any} == any()
    end
    test "works in matches" do
      assert any() = %Type{name: :any}
    end
  end

  describe "none/0 type" do
    test "works in use" do
      assert %Type{name: :none} == none()
    end
    test "works in matches" do
      assert none() = %Type{name: :none}
    end
  end

  describe "pos_integer/0 type" do
    test "works in use" do
      assert %Type{name: :pos_integer} == pos_integer()
    end
    test "works in matches" do
      assert pos_integer() = %Type{name: :pos_integer}
    end
  end

  describe "neg_integer/0 type" do
    test "works in use" do
      assert %Type{name: :neg_integer} == neg_integer()
    end
    test "works in matches" do
      assert neg_integer() = %Type{name: :neg_integer}
    end
  end

  describe "float/0 type" do
    test "works in use" do
      assert %Type{name: :float} == float()
    end
    test "works in matches" do
      assert float() = %Type{name: :float}
    end
  end

  describe "node/0 type" do
    test "works in use" do
      assert %Type{name: :node} == type(node())
    end
    test "works in matches" do
      assert type(node()) = %Type{name: :node}
    end
  end

  describe "module/0 type" do
    test "works in use" do
      assert %Type{name: :module} == module()
    end
    test "works in matches" do
      assert module() = %Type{name: :module}
    end
  end

  describe "atom/0 type" do
    test "works in use" do
      assert %Type{name: :atom} == atom()
    end
    test "works in matches" do
      assert atom() = %Type{name: :atom}
    end
  end

  describe "pid/0 type" do
    test "works in use" do
      assert %Type{name: :pid} == pid()
    end
    test "works in matches" do
      assert pid() = %Type{name: :pid}
    end
  end

  describe "port/0 type" do
    test "works in use" do
      assert %Type{name: :port} == port()
    end
    test "works in matches" do
      assert port() = %Type{name: :port}
    end
  end

  describe "reference/0 type" do
    test "works in use" do
      assert %Type{name: :reference} == reference()
    end
    test "works in matches" do
      assert reference() = %Type{name: :reference}
    end
  end

  describe "iolist/0 type" do
    test "works in use" do
      assert %Type{name: :iolist} == iolist()
    end
    test "works in matches" do
      assert iolist() = %Type{name: :iolist}
    end
  end
end
