defmodule TyperatorTest.TypeableTest do
  use ExUnit.Case, async: true

  @moduletag :typeable

  describe "literal values are typed for" do
    test "atoms" do
      assert %Type{name: :foo, module: :atom} = Type.of(:foo, __ENV__)
    end
    test "strings" do
      assert %Type{name: :t, module: String} = Type.of("foo", __ENV__)
    end
    test "integers" do
      assert 47 = Type.of(47, __ENV__)
    end
    test "floats" do
      assert %Type{name: :float, module: nil} = Type.of(47.0, __ENV__)
    end
  end

  describe "quad values from typespecs can be typed" do
    test "integers" do
      assert %Type{name: :integer, module: nil} =
        Type.of({:type, 47, :integer, []}, __ENV__)
    end
    test "functions" do
      int_type = {:type, 47, :integer, []}
      fun_type = {:type, 47, :fun, [{:type, 17, :product, [int_type]}, int_type]}

      assert %Type.Function{
        params: [%Type{name: :integer}],
        return: %Type{name: :integer}} = Type.of(fun_type, __ENV__)
    end
  end

  describe "specs can be typed" do
    alias Type.Function

    test "for functions" do
      spec = quote do foo(integer) :: String.t end

      assert {:foo, %Function{
        params: [%Type{name: :integer}],
        return: %Type{name: :t, module: String}
      }} = Function.from_spec(spec, %{__ENV__ | context: :spec})
    end

    test "for types" do
      type = quote do String.t end

      assert %Type{name: :t, module: String} =
        Type.of(type, %{__ENV__ | context: :spec})
    end

    test "for basic types" do
      type = quote do integer end
      assert %Type{name: :integer} = Type.of(type, %{__ENV__ | context: :spec})
    end
  end
end
