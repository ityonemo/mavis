defmodule TypeTest.BuiltinPort.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the port type" do
    pull_types(defmodule Port do
      @type port_type :: port()
    end)

    test "is presented as itself" do
      assert "port()" == inspect(@port_type)
    end

    test "code translates correctly" do
      assert @port_type == eval_inspect(@port_type)
    end
  end
end
