defmodule TypeTest.BuiltinIolist.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the iolist type" do
    pull_types(defmodule Iolist do
      @type iolist_type :: iolist
      @type iolist_plus :: iolist | nil
    end)

    test "looks like a iolist" do
      assert "iolist()" == inspect(@iolist_type)
    end

    test "code translates correctly" do
      assert @iolist_type == eval_inspect(@iolist_type)
    end

    test "iolist plus works" do
      assert "nil <|> iolist()" = inspect(@iolist_plus)
    end
  end
end
