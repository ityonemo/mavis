defmodule TypeTest do

  # tests on the Type module
  use ExUnit.Case, async: true

  # allows us to use these in doctests
  import Type, only: :macros

  doctest Type

  # tests on types
  doctest Type.Bitstring
  doctest Type.Function
  doctest Type.List
  doctest Type.NoInference
  doctest Type.Tuple
  doctest Type.Map
  doctest Type.Union
end
