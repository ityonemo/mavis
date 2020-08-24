defmodule TypeTest.UnionCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :union

  alias Type.Union

  import Type, only: :macros

  test "coercion for unions"

end
