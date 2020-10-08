defmodule TypeTest.TypeExample do

  defmodule Basics do
    @type any_type :: any
    @type term_type :: term
    @type none_type :: none

    @type pid_type :: pid
    @type port_type :: port
    @type reference_type :: reference
    @type identifier_type :: identifier
  end

  defmodule Numbers do
    @type literal_int :: 47
    @type literal_neg_int :: -47

    @type range :: 7..47
    @type neg_range :: -47..-7

    @type float_type :: float

    @type integer_type :: integer
    @type neg_integer_type :: neg_integer
    @type pos_integer_type :: pos_integer
    @type non_neg_integer_type :: non_neg_integer

    @type arity_type :: arity
    @type byte_type :: byte
    @type char_type :: char

    @type number_type :: number
    @type timeout_type :: timeout
  end

end
