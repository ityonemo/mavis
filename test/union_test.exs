defmodule TypeTest.UnionTest do
  use ExUnit.Case, async: true

  @moduletag :union

  alias Type.Union

  test "unions are collectibles" do
    assert 1 = Enum.into([1], %Union{of: []})
    assert %Union{of: [1, 3]} = Enum.into([1, 3], %Union{of: []})
  end
end
