defmodule TypeTest.BuiltinPort.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Port do
    @type port_type :: port()
  end)

  describe "the port/0 type" do
    test "is itself" do
      assert port() == @port_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :port, params: []} == @port_type
    end
  end
end
