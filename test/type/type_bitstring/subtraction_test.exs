defmodule TypeTest.TypeBitstring.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtraction

  import Type, only: :macros

  alias Type.Bitstring

  @empty_bitstring %Bitstring{size: 0, unit: 0}

  test "go through and make sure that all @moduletags are correct"
  test "go through and verify all describe and test strings"

  describe "the subtraction from empty bitstring" do
    test "of itself and any is itself" do
      assert none() == @empty_bitstring - any()
      assert none() == @empty_bitstring - @empty_bitstring
    end

    test "of any string with size 0 is none" do
      assert none() == @empty_bitstring - bitstring()
      assert none() == @empty_bitstring - binary()
    end

    test "of the literal empty bitstring is none" do
      assert none() == @empty_bitstring - ""
    end

    test "with any fixed size string is itself" do
      assert @empty_bitstring == @empty_bitstring - %Bitstring{size: 8, unit: 0}
      assert @empty_bitstring == @empty_bitstring - %Bitstring{size: 8, unit: 8}
    end

    test "of all other types is itself" do
      TypeTest.Targets.except([@empty_bitstring, ""])
      |> Enum.each(fn target ->
        assert @empty_bitstring == @empty_bitstring - target
      end)
    end
  end

  describe "the subtraction from basic bitstring" do
    test "of itself and any is none" do
      assert none() == bitstring() - any()
      assert none() == bitstring() - bitstring()
    end

    test "of any string with a fixed size is a straight subtraction" do
      assert %Bitstring{size: 0} <|> %Bitstring{size: 1} <|> %Bitstring{size: 2} <|> %Bitstring{size: 4, unit: 1} ==
        bitstring() - %Bitstring{size: 3}
    end

    test "of any string with unit not 1 is a complementation" do
      assert %Bitstring{size: 2, unit: 3} <|> %Bitstring{size: 1, unit: 3} ==
        bitstring() - %Bitstring{unit: 3}
      assert for i <- 1..7, do: %Bitstring{size: i, unit: 8} == bitstring() - binary()
    end

    test "when there is preceding size it's filled in" do
      assert %Bitstring{} <|> %Bitstring{size: 3} <|>
        %Bitstring{size: 2, unit: 3} <|> %Bitstring{size: 1, unit: 3} ==
        bitstring() - %Bitstring{size: 6, unit: 3}

      assert %Bitstring{size: 1} <|> %Bitstring{size: 2, unit: 3} <|> %Bitstring{unit: 3} ==
        bitstring() - %Bitstring{size: 4, unit: 3}
    end
  end

  test "empty bitstring literal stuff"

  describe "the subtraction from basic binary" do
    test "of itself, bitstring and any is none" do
      assert none() == binary() - any()
      assert none() == binary() - bitstring()
      assert none() == binary() - binary()
    end
  end


  describe "other combinations of bitstrings:" do
    test "when lhs and rhs have fixed size" do
      assert none() == %Bitstring{size: 15, unit: 0} - %Bitstring{size: 15, unit: 0}
      assert %Bitstring{size: 15, unit: 0} ==
        %Bitstring{size: 15, unit: 0} - %Bitstring{size: 13, unit: 0}
    end

    test "when only the lhs has fixed size" do
      assert none() == %Bitstring{size: 15} - %Bitstring{unit: 3}
      assert none() == %Bitstring{size: 15} - %Bitstring{size: 3, unit: 4}
      assert %Bitstring{size: 15} ==
        %Bitstring{size: 15, } - %Bitstring{unit: 4}
      assert %Bitstring{size: 15} ==
        %Bitstring{size: 15} - %Bitstring{size: 18, unit: 3}
    end

    test "when only the rhs has fixed size" do
      assert %Bitstring{size: 4, unit: 3} ==
        %Bitstring{size: 4, unit: 3} - %Bitstring{size: 9}
      assert %Bitstring{size: 4, unit: 3} ==
        %Bitstring{size: 4, unit: 3} - %Bitstring{size: 1}
      assert %Bitstring{size: 7, unit: 3} ==
        %Bitstring{size: 4, unit: 3} - %Bitstring{size: 4}
      assert %Bitstring{size: 4} <|> %Bitstring{size: 10, unit: 3} ==
        %Bitstring{size: 4, unit: 3} - %Bitstring{size: 7}

      assert %Bitstring{size: 4} <|> %Bitstring{size: 7} <|> %Bitstring{size: 13, unit: 3} ==
        %Bitstring{size: 4, unit: 3} - %Bitstring{size: 10}
    end

    test "calculates the correct residual slices for variable bitstrings" do
      assert %Bitstring{size: 1, unit: 6} ==
        %Bitstring{size: 1, unit: 3} - %Bitstring{size: 0, unit: 2}
    end

    use ExUnitProperties
    @tag :property
    test "all subtractions are valid" do
      check all size1 <- StreamData.integer(0..255),
                size2 <- StreamData.integer(0..255),
                unit1 <- StreamData.integer(0..255),
                unit2 <- StreamData.integer(0..255) do #, max_runs: 100 do
        difference =
          %Bitstring{size: size1, unit: unit1} -
          %Bitstring{size: size2, unit: unit2}

        Enum.each(0..100, fn m ->
          refute %Bitstring{size: size2 + m * unit2} in difference

          bs1val = %Bitstring{size: size1 + m * unit1}

          consistent = (bs1val in difference) or (bs1val in %Bitstring{size: size2, unit: unit2})

          unless consistent do
            bs1val |> IO.inspect(label: "136")
            difference |> IO.inspect(label: "137")
            (bs1val in difference) |> IO.inspect(label: "138")
          end

          assert consistent
        end)
      end
    end
  end

end
