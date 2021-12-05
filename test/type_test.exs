defmodule TypeTest do
  # tests on the Type module
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :doctests

  doctest Type
  doctest Type.Bitstring
  doctest Type.Function
  doctest Type.List
  doctest Type.NoInference
  doctest Type.Tuple
  doctest Type.Map
  doctest Type.Union
end
