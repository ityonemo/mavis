defmodule TypeTest.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @moduletag :property

  test "does term typing obey term order?" do
    check all term1 <- term(),
              term2 <- term() do
      cond do
        is_float(term1) and is_integer(term2) ->
          Type.of(term1) > Type.of(term2)

        is_integer(term1) and is_float(term2) ->
          Type.of(term2) > Type.of(term1)

        term1 === term2 ->
          Type.of(term1) == Type.of(term2)

        term1 < term2 ->
          Type.of(term1) <= Type.of(term2)

        term1 > term2 ->
          Type.of(term1) >= Type.of(term2)
      end
    end
  end

end
