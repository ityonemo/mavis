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

  defmodule Atoms do
    @type literal_atom :: :literal
    @type atom_type :: atom
    @type boolean_type :: boolean
    @type module_type :: module
    @type node_type :: node
  end

  defmodule Functions do
    # literals
    @type zero_arity :: (-> any)
    @type two_arity :: (integer, atom -> float)
    @type any_arity :: (... -> any)
    @type fun_type :: fun
    @type function_type :: function
  end

  defmodule Tuples do
    @type empty_literal :: {}
    @type ok_literal :: {:ok, any}
    @type tuple_type :: tuple
    @type mfa_type :: mfa
  end

end
