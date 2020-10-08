defmodule TypeTest.SpecExample do
  defmodule Builtins do
    @spec any_spec(any) :: any
    def any_spec(x), do: x

    @spec none_spec(any) :: none
    def none_spec(_), do: raise "foo"

    @spec pid_spec(pid) :: pid
    def pid_spec(x), do: x

    @spec port_spec(port) :: port
    def port_spec(x), do: x

    @spec reference_spec(reference) :: reference
    def reference_spec(x), do: x

    @spec identifier_spec(identifier) :: identifier
    def identifier_spec(x), do: x

    @spec as_boolean_spec(as_boolean(:foo)) :: as_boolean(:foo)
    def as_boolean_spec(x), do: x
  end

  defmodule Numbers do
    # literals
    @spec literal_spec(47) :: 47
    def literal_spec(x), do: x

    @spec range_spec(7..47) :: 7..47
    def range_spec(x), do: x

    # builtins
    @spec float_spec(float) :: float
    def float_spec(x), do: x

    @spec integer_spec(integer) :: integer
    def integer_spec(x), do: x

    @spec neg_integer_spec(neg_integer) :: neg_integer
    def neg_integer_spec(x), do: x

    @spec non_neg_integer_spec(non_neg_integer) :: non_neg_integer
    def non_neg_integer_spec(x), do: x

    @spec pos_integer_spec(pos_integer) :: pos_integer
    def pos_integer_spec(x), do: x

    # special builtin
    @spec arity_spec(arity) :: arity
    def arity_spec(x), do: x

    @spec byte_spec(byte) :: byte
    def byte_spec(x), do: x

    @spec char_spec(char) :: char
    def char_spec(x), do: x

    @spec number_spec(number) :: number
    def number_spec(x), do: x

    @spec timeout_spec(timeout) :: timeout
    def timeout_spec(timeout), do: timeout
  end

  defmodule Atoms do
    # literals
    @spec literal_spec(:literal) :: :literal
    def literal_spec(x), do: x

    # builtins
    @spec atom_spec(atom) :: atom
    def atom_spec(x), do: x

    @spec boolean_spec(boolean) :: boolean
    def boolean_spec(x), do: x

    @spec module_spec(module) :: module
    def module_spec(x), do: x

    @spec node_spec(node) :: node
    def node_spec(x), do: x
  end

  defmodule Functions do
    # literals
    @spec zero_arity_spec((-> any)) :: (-> any)
    def zero_arity_spec(x), do: x

    @spec two_arity_spec((any, any -> any)) :: (any, any -> any)
    def two_arity_spec(x), do: x

    @spec any_arity_spec((... -> integer)) :: (... -> integer)
    def any_arity_spec(x), do: x

    @spec fun_spec(fun) :: fun
    def fun_spec(x), do: x

    @spec function_spec(function) :: function
    def function_spec(x), do: x
  end

  defmodule Tuples do
    # literals
    @spec empty_literal_spec({}) :: {}
    def empty_literal_spec(x), do: x

    @spec ok_literal_spec({:ok, any}) :: {:ok, any}
    def ok_literal_spec(x), do: x

    # builtins
    @spec tuple_spec(tuple) :: tuple
    def tuple_spec(x), do: x

    @spec mfa_spec(mfa) :: mfa
    def mfa_spec(x), do: x
  end

  defmodule Lists do
    @spec literal_1_spec([integer]) :: [integer]
    def literal_1_spec(x), do: x

    @spec literal_0_spec([]) :: []
    def literal_0_spec(x), do: x

    @spec nonempty_any_spec([...]) :: [...]
    def nonempty_any_spec(x), do: x

    @spec nonempty_typed_spec([integer, ...]) :: [integer, ...]
    def nonempty_typed_spec(x), do: x

    @spec keyword_literal_spec([foo: integer]) :: [foo: integer]
    def keyword_literal_spec(x), do: x

    @spec keyword_2_literal_spec([foo: integer, bar: float]) :: [foo: integer, bar: float]
    def keyword_2_literal_spec(x), do: x

    @spec list_1_spec(list(integer)) :: list(integer)
    def list_1_spec(x), do: x

    @spec nonempty_list_1_spec(nonempty_list(integer)) :: nonempty_list(integer)
    def nonempty_list_1_spec(x), do: x

    @spec maybe_improper_list_2_spec(maybe_improper_list(integer, nil)) :: maybe_improper_list(integer, nil)
    def maybe_improper_list_2_spec(x), do: x

    @spec nonempty_improper_list_2_spec(nonempty_improper_list(integer, nil)) :: nonempty_improper_list(integer, nil)
    def nonempty_improper_list_2_spec(x), do: x

    @spec nonempty_maybe_improper_list_2_spec(nonempty_maybe_improper_list(integer, nil)) ::
      nonempty_maybe_improper_list(integer, nil)
    def nonempty_maybe_improper_list_2_spec(x), do: x

    @spec charlist_spec(charlist) :: charlist
    def charlist_spec(x), do: x

    @spec nonempty_charlist_spec(nonempty_charlist) :: nonempty_charlist
    def nonempty_charlist_spec(x), do: x

    @spec keyword_0_spec(keyword) :: keyword
    def keyword_0_spec(x), do: x

    @spec keyword_1_spec(keyword(integer)) :: keyword(integer)
    def keyword_1_spec(x), do: x

    @spec nonempty_list_0_spec(nonempty_list) :: nonempty_list
    def nonempty_list_0_spec(x), do: x

    @spec maybe_improper_list_0_spec(maybe_improper_list) :: maybe_improper_list
    def maybe_improper_list_0_spec(x), do: x

    @spec nonempty_maybe_improper_list_0_spec(nonempty_maybe_improper_list) :: nonempty_maybe_improper_list
    def nonempty_maybe_improper_list_0_spec(x), do: x
  end

  defmodule Bitstrings do
    @spec empty_bitstring_spec(<<>>) :: <<>>
    def empty_bitstring_spec(x), do: x

    @spec sized_bitstring_spec(<<_::47>>) :: <<_::47>>
    def sized_bitstring_spec(x), do: x

    @spec unit_bitstring_spec(<<_::_*8>>) :: <<_::_*8>>
    def unit_bitstring_spec(x), do: x

    @spec size_unit_bitstring_spec(<<_::12, _::_*8>>) :: <<_::12, _::_*8>>
    def size_unit_bitstring_spec(x), do: x

    @spec binary_spec(binary) :: binary
    def binary_spec(x), do: x

    @spec bitstring_spec(bitstring) :: bitstring
    def bitstring_spec(x), do: x

    @spec iodata_spec(iodata) :: iodata
    def iodata_spec(x), do: x

    @spec iolist_spec(iolist) :: iolist
    def iolist_spec(x), do: x
  end

  defmodule Maps do
    defstruct [:foo]

    @spec empty_map_spec(%{}) :: %{}
    def empty_map_spec(x), do: x

    @spec atom_key_spec(%{atom: integer}) :: %{atom: integer}
    def atom_key_spec(x), do: x

    @spec required_literal_spec(%{required(:foo) => integer}) :: %{required(:foo) => integer}
    def required_literal_spec(x), do: x

    @spec optional_literal_spec(%{optional(:foo) => integer}) :: %{optional(:foo) => integer}
    def optional_literal_spec(x), do: x

    @spec struct_literal_spec(%__MODULE__{}) :: %__MODULE__{}
    def struct_literal_spec(x), do: x

    @spec struct_defined_literal_spec(%__MODULE__{foo: integer}) ::
      %__MODULE__{foo: integer}
    def struct_defined_literal_spec(x), do: x

    @spec map_spec(map) :: map
    def map_spec(x), do: x

    @spec struct_spec(struct) :: struct
    def struct_spec(x), do: x
  end

end
