defmodule TypeTest.BuiltinIodata.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the iodata type" do
    pull_types(defmodule Iodata do
      @type iodata_type :: iodata
      @type iodata_plus :: iodata | nil
    end)

    test "looks like a iodata" do
      assert "iodata()" == inspect(@iodata_type)
    end

    test "code translates correctly" do
      assert @iodata_type == eval_inspect(@iodata_type)
    end

    test "iodata plus works" do
      assert "iodata() <|> nil" = inspect(@iodata_plus)
    end
  end
end
