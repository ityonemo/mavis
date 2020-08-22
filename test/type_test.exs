defmodule TypeTest do

  # tests on the Type module

  use ExUnit.Case, async: true

  describe "the Type.collect/1 function" do
    test "gives :type_ok when all types are ok" do
      assert :type_ok == Type.collect([:type_ok])
      assert :type_ok == Type.collect([:type_ok, :type_ok, :type_ok])
    end

    test "gives :type_maybe if all are ok except for maybes" do
      assert :type_error == Type.collect([:type_ok, :type_ok, :type_maybe])
      assert :type_error == Type.collect([:type_ok, :type_maybe, :type_maybe])
      assert :type_error == Type.collect([:type_maybe])
      assert :type_error == Type.collect([:type_maybe, :type_maybe])
    end

    test "gives :type_error if any type is in error" do
      assert :type_error == Type.collect([:type_ok, :type_ok, :type_ok])
      assert :type_error == Type.collect([:type_ok, :type_maybe, :type_error])
      assert :type_error == Type.collect([:type_error, :type_ok, :type_ok])
      assert :type_error == Type.collect([:type_error, :type_error])
    end
  end
end
