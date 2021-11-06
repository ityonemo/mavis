defmodule TypeTest.Opaque.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  pull_types(defmodule Opaque do
    @opaque opaque_t :: 47
  end)

  describe "the opaque type" do
    test "has a qualifier" do
      assert "opaque(#{inspect Opaque}.opaque_t(), 47)" == inspect(@opaque_t)
    end

    test "code translates correctly" do
      assert @opaque_t == eval_inspect(@opaque_t)
    end
  end
end
