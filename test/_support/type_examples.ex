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

  defmodule Lists do
    @type literal_0 :: []
    @type literal_1 :: [integer]

    @type nonempty_any :: [...]
    @type nonempty_typed :: [integer, ...]
    @type keyword_literal :: [foo: integer]
    @type keyword_2_literal :: [foo: integer, bar: float]

    @type list_0 :: list()
    @type list_1 :: list(integer)
    @type nonempty_list_1 :: nonempty_list(integer)
    @type maybe_improper_list_2 :: maybe_improper_list(integer, nil)
    @type nonempty_improper_list_2 :: nonempty_improper_list(integer, nil)
    @type nonempty_maybe_improper_list_2 :: nonempty_maybe_improper_list(integer, nil)

    @type charlist_type :: charlist
    @type nonempty_charlist_type :: nonempty_charlist

    @type keyword_0 :: keyword
    @type keyword_1 :: keyword(integer)

    @type nonempty_list_0 :: nonempty_list
    @type maybe_improper_list_0 :: maybe_improper_list
    @type nonempty_maybe_improper_list_0 :: nonempty_maybe_improper_list
  end

  defmodule Bitstrings do
    @type empty_bitstring :: <<>>
    @type size_bitstring :: <<_::47>>
    @type unit_bitstring :: <<_::_*8>>
    @type size_unit_bitstring :: <<_::12, _::_*8>>

    @type binary_type :: binary
    @type bitstring_type :: bitstring

    @type iodata_type :: iodata
    @type iolist_type :: iolist
  end

  defmodule Maps do
    defstruct [:foo]

    @type empty_map_type :: %{}
    @type atom_key_type :: %{atom: integer}
    @type required_literal_type :: %{required(:foo) => integer}
    @type optional_literal_type :: %{optional(:foo) => integer}
    @type struct_literal_type :: %__MODULE__{}
    @type struct_defined_literal_type :: %__MODULE__{foo: integer}

    @type map_type :: map
    @type struct_type :: struct
  end

  defmodule Unions do
    @type of_atoms :: :foo | :bar
  end

  defmodule Remote do
    @type elixir_string :: String.t
    @type foobar :: Foo.bar(integer)
    @type with_arity(t) :: t
  end
end
