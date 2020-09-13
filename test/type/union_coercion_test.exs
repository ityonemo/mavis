defmodule TypeTest.UnionCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :union

  alias Type.Union

  import Type, only: [builtin: 1]

  test "coercion for unions"

end
