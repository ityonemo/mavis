defmodule Type do

  @moduledoc """
  Type analysis system for Elixir.

  Mavis implements the `Type` module, which contains a type analysis system
  specifically tailored for the BEAM VM.  The following considerations went
  into its design.

  - Must be compatible with the existing dialyzer/typespec system
  - May extend the typespec system if it's unobtrusive and can be, at
    a minimum, *'opt-out'*.
  - Does not have to conform to existing theoretical typesystems (e.g.
    [H-M](https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system))
  - Take maximum advantage of Elixir programming features to achieve
    readability and extensibility.
  - Does not have to be easily usable from erlang, but must be able to
    handle modules produced in erlang.

  You can read more about the Mavis typesystem [here](typesystem.html), and
  deviations from dialyzer types in the following documents:
  - [strings](string_deviations.html)
  - [functions](function_deviations.html)
  - [tuples](tuple_deviations.html)

  ### Compile-Time Usage

  The type analysis system is designed to be a backend for a compile-time
  typechecker (see [Selectrix](https://github.com/ityonemo/selectrix)).  This
  system will infer the types of functions in modules and emit errors and
  warnings if there appear to be conflicts.

  One key function enabling this is `fetch_type!/3`; you can use this function
  to retrieve typing information on typing information stored in modules that
  have already been compiled.

  ```elixir
  iex> inspect Type.fetch_type!(String, :t, [])
  "binary()"
  ```

  ### Runtime Usage

  There's no reason why you have to use the typing library exclusively at
  compile-time.  Here is an example of using it at runtime:

  ```
  defmodule TestJson do
    @type json :: String.t | number | boolean | nil | [json] | %{optional(String.t) => json}

    def validate_json(data) do
      json_type = Type.fetch_type!(__MODULE__, :json, [])

      if Type.type_match?(json_type, data), do: :ok, else: raise "not json"
    end
  end
  ```

  Note that the above example is not particularly performant.

  ### Examples:

  ```elixir
  iex> import Type, only: :macros
  iex> inspect Type.union(non_neg_integer(), :infinity)
  "timeout()"
  iex> Type.intersect(pos_integer(), -10..10)
  1..10
  ```

  The `Type` module implements two things:

  1. Core functionality for all typesytem operations.
  2. Support data structure for generic builtin and remote types.

  ## Type representation in Mavis

  The `Type` data structure is a struct with three parameters:
  - `module`: The module in which the type is defined; `nil` for builtins.
  - `name`: (atom) of the type
  - `params`: a list of type arguments to the type data structure.  These
    must be types themselves "as applied" to the type definition if we
    consider it to be a function.

  ### Representing other types.

  The following literals are represented directly:
  - integers
  - `Range`s (must be increasing)
  - atoms
  - empty list (`[]`)
  - lists
  - floats
  - bitstrings

  Literal maps and tuples are definable using their respective types.
  See `Type.Map` and `Type.Tuple`

  The following types have associated structs:
  - lists: `t:Type.List.t/0`
  - bitstrings/binaries: `t:Type.Bitstring.t/0`
  - tuples: `t:Type.Tuple.t/0`
  - maps: `t:Type.Map.t/0`
  - funs: `t:Type.Function.t/0`

  The following "type containers" have associated structs:
  - unions: `t:Type.Union.t/0`
  - opaque types: `t:Type.Opaque.t/0`
  - function vars: `t:Type.Function.Var.t/0`

  ## Supported Type operations

  The Mavis typesystem provides five primary operations, which might not
  necessarily be the set of operations that one expects from a typesystem.
  These operations are chosen specifically reflect the needs of Erlang and
  Elixir's dynamic types and the type specification system provided by
  dialyzer.

  - `Type.union/1`
  - `Type.intersect/1`
  - `Type.subtype?/2`
  - `Type.usable_as/3`
  - `Type.of/1`

  The operation `Type.type_match?/2` is also provided, which is a combination of
  `Type.of/1` and `Type.subtype?/2`.

  ## Deviations from standard Elixir and Erlang

  ### The Curious case of String.t

  `t:String.t/0` has a special meaning in Elixir, it is a UTF-8 encoded
  `t:binary/0`.  As such, it is special-cased to have some properties that
  other remote types don't have out of the box.  This sort of behaviour
  may be changed to be extensible to custom types in a future release.

  ### "Aliased builtins"

  Some builtins were not directly introduced into the typesystem logic, since
  they are easily represented as aliases or composite types.  The following
  aliased builtins are usable with the `builtin/1` macro, but will return false
  with `is_primitive/1`

  **NB in the future the name of `is_primitive` may change to prevent confusion.**

  - `t:term/0`
  - `t:integer/0`
  - `t:non_neg_integer/0`
  - `t:arity/0`
  - `t:as_boolean/1`
  - `t:binary/0`
  - `t:bitstring/0`
  - `t:byte/0`
  - `t:char/0`
  - `t:charlist/0`
  - `t:nonempty_charlist/0`
  - `t:fun/0`
  - `t:function/0`
  - `t:identifier/0`
  - `t:iodata/0`
  - `t:keyword/0`
  - `t:keyword/1`
  - `t:list/0`
  - `t:nonempty_list/0`
  - `t:maybe_improper_list/0`
  - `t:nonempty_maybe_improper_list/0`
  - `t:mfa/0`
  - `t:no_return/0`
  - `t:number/0`
  - `t:struct/0`
  - `t:timeout/0`

  ```elixir
  iex> import Type, only: :macros
  iex> timeout()
  %Type.Union{of: [:infinity, %Type{name: :pos_integer}, 0]}
  iex> Type.is_primitive(timeout())
  false
  ```

  ### Module and Node detail

  The `t:module/0` and `t:node/0` types are given extra protection.

  An atom will not be considered a module unless it is detected to exist
  in the VM; although for `usable_as/3` it will return the `:maybe` result
  if unconfirmed.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.type_match?(module(), :foo)
  false
  iex> Type.type_match?(module(), Kernel)
  true
  iex> Type.type_match?(module(), :gen_server)
  true
  iex> Type.usable_as(Enum, module())
  :ok
  iex> Type.usable_as(:not_a_module, module())
  {:maybe, [%Type.Message{target: %Type{name: :module}, type: :not_a_module}]}
  ```

  A node will not be considered a node unless it has the proper form for a
  node.  `usable_as/3` does not check active node lists, however.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.type_match?(type(node()), :foo)
  false
  iex> Type.type_match?(type(node()), :nonode@nohost)
  true
  ```
  """

  @enforce_keys [:name]
  defstruct @enforce_keys ++ [:module, params: []]

  @type t :: %__MODULE__{
    name: atom,
    module: nil | module,
    params: [t]
  } | integer | Range.t | float
  | atom
  #| Type.AsBoolean.t
  | Type.Function.t
  | Type.Tuple.t
  | Type.Map.t
  | Type.List.t | [] | list
  | Type.Bitstring.t | bitstring
  | Type.Union.t
  | Type.Opaque.t
  | Type.Function.Var.t
  | Type.Subtraction.t

  @type literal ::
    integer | float | atom | bitstring | [] | [literal] |
    Type.Map.t(literal, literal) | Type.Tuple.t(literal)

  @typedoc """
  Represents that some but not all members of the type will succeed in
  the operation.

  should typically result in a compile-time warning.

  output by `Type.usable_as/3`
  """
  @type maybe :: {:maybe, [Type.Message.t]}

  @typedoc """
  No members of this type will succeed in the operation.

  should typically result in a compile-time error.

  output by `Type.usable_as/3`
  """
  @type error  :: {:error, Type.Message.t}

  @typedoc """
  output type for `Type.usable_as/3`
  """
  @type ternary :: :ok | maybe | error

  @doc "guard for when a ternary value is an error"
  defguard is_error(t) when elem(t, 0) == :error

  @doc "guard for when a ternary value is not an error"
  defguard is_not_error(t) when t == :ok or (elem(t, 0) == :maybe)

  import Type.Builtins

  defbuiltin do
    # primitive builtins
    basic :none
    basic :neg_integer
    basic :pos_integer
    basic :float
    basic :node
    basic :module
    basic :atom
    basic :pid
    basic :port
    basic :reference
    basic :iolist
    basic :any

    ## composite builtins (but under "basic" in the docs)
    builtin :non_neg_integer,
               %Type.Union{of: [%Type{module: nil, name: :pos_integer, params: []}, 0]},
               "%Type.Union{of: [pos_integer(), 0]}"
    builtin :integer,
               %Type.Union{of: [
                 %Type{module: nil, name: :pos_integer, params: []},
                 0,
                 %Type{module: nil, name: :neg_integer, params: []}]},
               "%Type.Union{of: [pos_integer(), 0, neg_integer()]}"
    builtin :map,
               %Type.Map{optional: %{
                 %Type{module: nil, name: :any, params: []} => %Type{module: nil, name: :any, params: []}}},
               "%Type.Map{optional: %{any() => any()}}"
    builtin :tuple,
               %Type.Tuple{elements: [], fixed: false},
               "%Type.Tuple{elements: [], fixed: false}"
    # composite builtins (built-in types)
    builtin :no_return, %Type{module: nil, name: :none, params: []}, "none()"
    builtin :arity, 0..255, "0..255"
    builtin :byte, 0..255, "0..255"
    builtin :char, 0..0x10_FFFF, "0..0x10_FFFF"
    builtin :number,
               %Type.Union{of: [%Type{module: nil, name: :float, params: []}, %Type{module: nil, name: :pos_integer, params: []}, 0, %Type{module: nil, name: :neg_integer, params: []}]},
               "%Type.Union{of: [float(), pos_integer(), 0, neg_integer()]}"
    builtin :timeout,
               %Type.Union{of: [:infinity, %Type{module: nil, name: :pos_integer, params: []}, 0]},
               "%Type.Union{of: [:infinity, pos_integer(), 0]}"
    builtin :boolean,
               %Type.Union{of: [true, false]},
               "%Type.Union{of: [true, false]}"
    builtin :identifier,
               %Type.Union{of: [
                 %Type{module: nil, name: :pid, params: []},
                 %Type{module: nil, name: :port, params: []},
                 %Type{module: nil, name: :reference, params: []}]},
               "%Type.Union{of: [pid(), port(), reference()]}"
    builtin :fun,
               %Type.Function{branches: [%Type.Function.Branch{params: :any, return: %Type{module: nil, name: :any, params: []}}]},
               "%Type.Function{branches: [%Type.Function.Branch{params: :any, return: any()}]}"
    builtin :function,
               %Type.Function{branches: [%Type.Function.Branch{params: :any, return: %Type{module: nil, name: :any, params: []}}]},
               "%Type.Function{branches: [%Type.Function.Branch{params: :any, return: any()}]}"
    builtin :mfa,
               %Type.Tuple{elements: [
                 %Type{module: nil, name: :module, params: []},
                 %Type{module: nil, name: :atom, params: []},
                 0..255],
               fixed: true},
               "%Type.Tuple{elements: [module(), atom(), arity()]}"
    builtin :struct,
               %Type.Map{
                 required: %{__struct__: %Type{module: nil, name: :module, params: []}},
                 optional: %{%Type{module: nil, name: :atom, params: []} => %Type{module: nil, name: :any, params: []}}},
               "%Type.Map{required: %{__struct__: module()}, optional: %{atom() => any()}}"
    builtin :nonempty_charlist,
               %Type.List{type: 0..0x10FFFF, final: []},
               "%Type.List{type: char()}"
    builtin :nonempty_list,
               %Type.List{type: %Type{module: nil, name: :any, params: []}, final: []},
               "%Type.List{type: any()}"
    builtin :nonempty_maybe_improper_list,
               %Type.List{
                 type: %Type{module: nil, name: :any, params: []},
                 final: %Type{module: nil, name: :any, params: []}},
               "%Type.List{type: any(), final: any()}"
    builtin :charlist,
              %Type.Union{of: [%Type.List{type: 0..0x10FFFF, final: []}, []]},
              "%Type.Union{of: [%Type.List{type: char(), final: []}, []]}"
    builtin :keyword,
               %Type.Union{of: [%Type.List{
                 type: %Type.Tuple{
                   elements: [
                     %Type{module: nil, name: :atom, params: []},
                     %Type{module: nil, name: :any, params: []}],
                   fixed: true},
                 final: []}, []]},
               "%Type.Union{of: [%Type.List{type: type({atom(), any()})}, []}"
    builtin :list,
               %Type.Union{of: [%Type.List{}, []]},
               "%Type.Union{of: [%Type.List{}, []]}"
    builtin :maybe_improper_list,
               %Type.Union{of: [%Type.List{type: %Type{module: nil, name: :any, params: []}, final: %Type{module: nil, name: :any, params: []}}, []]},
               "%Type.Union{of: [%Type.List{type: any(), final: any()}, []]}"
    builtin :binary,
               %Type.Bitstring{size: 0, unit: 8},
               "%Type.Bitstring{unit: 8}"
    builtin :iodata,
               %Type.Union{of: [%Type.Bitstring{size: 0, unit: 8, unicode: false}, %Type{module: nil, name: :iolist, params: []}]},
               "%Type.Union{of: [binary(), iolist()]}"
    builtin :bitstring,
               %Type.Bitstring{size: 0, unit: 1},
               "%Type.Bitstring{unit: 1}"
    builtin :term, %Type{module: nil, name: :any, params: []}, "%Type{name: :any}"

    ## nonstandard builtins (useful just for this library)
    builtin :nonempty_iolist,
               %Type.List{
                 type: %Type.Union{of: [%Type.Bitstring{size: 0, unit: 8, unicode: false}, %Type{module: nil, name: :any, params: []}, 0..255]},
                 final: %Type.Union{of: [%Type.Bitstring{size: 0, unit: 8, unicode: false}, []]}},
                 nil
    builtin :explicit_iolist,
               %Type.Union{of: [%Type.List{
                type: %Type.Union{of: [%Type.Bitstring{size: 0, unit: 8, unicode: false}, %Type{module: nil, name: :any, params: []}, 0..255]},
                final: %Type.Union{of: [%Type.Bitstring{size: 0, unit: 8, unicode: false}, []]}}, []]},
               nil
  end

  @doc type: true
  defmacro keyword(type) do
    quote do
      %Type.Union{
        of: [%Type.List{
          type: %Type.Tuple{
            elements: [Type.atom(), unquote(type)],
            fixed: true},
          final: []},
        []]}
    end
  end
  @doc """
  generates a list of a particular type.  A last parameter of `...`
  indicates that the list should be nonempty

  ### Examples:

  ```elixir
  iex> import Type, only: :macros
  iex> type([...])
  %Type.List{type: %Type{name: :any}}
  iex> list(1..10)
  %Type.Union{of: [%Type.List{type: 1..10}, []]}
  iex> nonempty_list(1..10)
  %Type.List{type: 1..10}
  ```

  if it's passed a keyword list, it is interpreted as a keyword list.

  ```elixir
  iex> import Type, only: :macros
  iex> type([foo: pos_integer()])
  %Type.List{type: %Type.Tuple{elements: [:foo, %Type{name: :pos_integer}]}}
  ```

  * usable in matches *
  """
  @doc type: true
  defmacro list(type) do
    quote do
      %Type.Union{of: [%Type.List{type: unquote(type), final: []}, []]}
    end
  end

  @doc """
  Creates a `t:nonempty_list/1`

  * usable in matches *

  ```elixir
  iex> nonempty_list(1..10)
  %Type.List{type: 1..10}
  ```
  """
  defmacro nonempty_list(type) do
    quote do %Type.List{type: unquote(type)} end
  end

  @doc """
  Creates a `t:maybe_improper_list/1`

  **NOTE**: not usable in matches and matches

  ```elixir
  iex> maybe_improper_list(:foo, :bar)
  %Type.Union{of: [%Type.List{type: :foo, final: %Type.Union{of: [[], :bar]}},[]]}
  ```
  """
  defmacro maybe_improper_list(type1, type2) do
    if __CALLER__.context == :match do
      raise CompileError,
        description: "can't use `maybe_improper_list/2` in a #{__CALLER__.context}",
        line: __CALLER__.line,
        file: __CALLER__.file
    end

    quote do
      %Type.Union{of: [
        %Type.List{type: unquote(type1), final: Type.union(unquote(type2), [])},
        []]}
    end
  end

  @doc """
  Creates a `t:nonempty_improper_list/2`

  * usable in matches *

  ```elixir
  iex> nonempty_improper_list(:foo, :bar)
  %Type.List{type: :foo, final: :bar}
  ```
  """
  defmacro nonempty_improper_list(type1, type2) do
    quote do
      %Type.List{type: unquote(type1), final: unquote(type2)}
    end
  end

  @doc """
  Creates a `t:nonempty_maybe_improper_list/2`.

  * not usable in matches *

  ```elixir
  iex> nonempty_maybe_improper_list(:foo, :bar)
  %Type.List{type: :foo, final: %Type.Union{of: [[], :bar]}}
  ```
  """
  defmacro nonempty_maybe_improper_list(type1, type2) do
    if __CALLER__.context == :match do
      raise CompileError,
        description: "can't use `maybe_improper_list/2` in a #{__CALLER__.context}",
        line: __CALLER__.line,
        file: __CALLER__.file
    end

    quote do
      %Type.List{type: unquote(type1), final: Type.union(unquote(type2), [])}
    end
  end

  def find_elements(elements, so_far \\ [])
  def find_elements([{:..., _, _}], so_far), do: {Enum.reverse(so_far), false}
  def find_elements([], so_far), do: {Enum.reverse(so_far), true}
  def find_elements([a | rest], so_far), do: find_elements(rest, [a | so_far])

  @doc """
  generates type literals.

  - For singletons (empty list, integers, atoms, bitstrings, floats),
    this is a no-op.
  - For lists, it expands into a list of the elements in their transformed
    state
  - For other composite values (maps and tuples), this gets decomposed to the
    structures as expected singletons
  - note that pids, ports, and references are not supported.

  ### Examples:

  ```elixir
  iex> import Type, only: :macros
  iex> Type.literal([])
  []
  iex> Type.literal(47)
  47
  iex> Type.literal(:foo)
  :foo
  iex> Type.literal("foo")
  "foo"
  iex> Type.literal(47.0)
  47.0
  iex> Type.literal([:foo, :bar])
  [:foo, :bar]
  iex> Type.literal([:foo | :bar])
  [:foo | :bar]
  iex> Type.literal([:foo, %{bar: "baz"}])
  [:foo, %Type.Map{required: %{bar: "baz"}}]
  iex> Type.literal([["foo"], "bar"])
  [["foo"], "bar"]
  iex> Type.literal(%{foo: :bar})
  %Type.Map{required: %{foo: :bar}}
  iex> Type.literal(%{foo: %{bar: "baz"}})
  %Type.Map{required: %{foo: %Type.Map{required: %{bar: "baz"}}}}
  iex> Type.literal({:ok, "bar"})
  %Type.Tuple{elements: [:ok, "bar"]}
  iex> Type.literal({:ok, "bar", 1})
  %Type.Tuple{elements: [:ok, "bar", 1]}
  iex> Type.literal(%{"foo" => "bar"})
  %Type.Map{required: %{"foo" => "bar"}}
  ```

  *usable in matches*
  """
  def literal(value) when
      is_atom(value) or
      is_number(value) or
      is_bitstring(value) or
      value == [] do
    value
  end
  def literal(list) when is_list(list) do
    Enum.map(list, &literal/1)
  end
  def literal(%module{} = struct) do
    requireds = struct
    |> Map.from_struct
    |> Map.new(fn {k, v} -> {literal(k), literal(v)} end)
    |> Map.put(:__struct__, module)

    %Type.Map{
      required: requireds,
      optional: %{}
    }
  end
  def literal(map) when is_map(map) do
    %Type.Map{
      required: Map.new(map, fn {k, v} -> {literal(k), literal(v)} end),
      optional: %{}
    }
  end
  def literal(tuple) when is_tuple(tuple) do
    %Type.Tuple{
      elements: tuple |> Tuple.to_list |> Enum.map(&literal/1)
    }
  end

  @doc """
  guard that tests if the selected type is remote

  ### Example:
  ```
  iex> Type.is_remote(:foo)
  false
  iex> Type.is_remote(%Type{name: :integer})
  false
  iex> Type.is_remote(%Type{module: String, name: :t})
  true
  ```
  """
  @doc guard: true
  defguard is_remote(type) when is_struct(type) and
    :erlang.map_get(:__struct__, type) == Type and
    :erlang.map_get(:module, type) != nil

  @doc """
  guard that tests if the selected type is builtin

  ### Example:
  ```
  iex> Type.is_primitive(:foo)
  false
  iex> Type.is_primitive(%Type{name: :integer})
  true
  iex> Type.is_primitive(%Type{module: String, name: :t})
  false
  ```

  Note that composite builtin types may not match with this
  function:

  ```
  iex> import Type, only: :macros
  iex> Type.is_primitive(mfa())
  false
  ```
  """
  @doc guard: true
  defguard is_primitive(type) when is_struct(type) and
    :erlang.map_get(:__struct__, type) == Type and
    :erlang.map_get(:module, type) == nil

  @spec usable_as(t, t, keyword) :: ternary
  @doc """
  Main utility function for determining type correctness.

  Answers the question:  If a system claims to require a certain "target
  type" to execute without crashing, what will happen if send a term that
  satisfies a "challenge type"?

  The result may be one of:
  - `:ok`, which signals that no crash will occur
  - `{:maybe, [messages]}`, which signals that a crash may occur due to
    one of the listed potential problems, but there are terms which will
    not trigger a crash.
  - `{:error, message}` which signals that all terms in the challenge
    type will trigger a crash.

  These three levels are intended to roughly correspond to:
  - "no notification to the user"
  - "emit a warning using `IO.warn/2`"
  - "halt compilation with `CompileError`"

  for a running compile-time analysis.

  `usable_as/3` also may be passed metadata which can be used to correctly
  craft warning and error messages; as well as being filters for user-defined
  exceptions to warning or error rules.

  ### Relationship to `subtype?/2`

  at first glance, it would seem that the `subtype?/2` function is
  equivalent to `usable_as/3`, but there are cases where the relationship
  is not as clear.  For example, if a function has the signature:

  `(integer() -> integer())`, that is not necessarily usable as a function
  that is `(any() -> integer())`, since it may be sent a value outside
  of the integers.  Conversely an `(any() -> integer())` function *IS*
  usable as an `(integer() -> integer())` function.  The subtyping
  relationship between these function types is unclear; in the Mavis
  system they are considered to be independent functions that are not
  subtypes of each other.

  ### Examples:
  ```
  iex> import Type, only: :macros
  iex> Type.usable_as(1, integer())
  :ok
  iex> Type.usable_as(1, neg_integer())
  {:error, %Type.Message{type: 1, target: neg_integer()}}
  iex> Type.usable_as(-10..10, neg_integer())
  {:maybe, [%Type.Message{type: -10..10, target: neg_integer()}]}
  ```

  ### Remote types:

  A remote type is intended to indicate that there is a quality outside of
  the type system which specifies the type.  Thus, a remote type should
  be usable as the type it encapsulates, but it should emit a `maybe` when
  going the other direction:

  ```
  iex> import Type, only: :macros
  iex> binary = %Type.Bitstring{size: 0, unit: 8}
  iex> Type.usable_as(type(String.t()), binary)
  :ok
  iex> Type.usable_as(binary, type(String.t))
  {:maybe, [%Type.Message{
              type: binary,
              target: type(String.t()),
              meta: [message: \"""
    binary() is an equivalent type to String.t() but it may fail because it is
    a remote encapsulation which may require qualifications outside the type system.
    \"""]}]}
  ```
  """
  defdelegate usable_as(challenge, target, meta \\ []), to: Type.Algebra

  @spec subtype?(t, t) :: boolean
  @doc """
  outputs whether one type is a subtype of itself.  To be true, the
  following condition must be satisfied:

  - if a term is in the first type, then it is also in the second type.

  Note that any type is automatically a subtype of itself.

  ### Examples:

  ```elixir
  iex> import Type, only: :macros
  iex> Type.subtype?(10, 1..47)
  true
  iex> Type.subtype?(10, integer())
  true
  iex> Type.subtype?(1..47, integer())
  true
  iex> Type.subtype?(integer(), 1..47)
  false
  iex> Type.subtype?(1..47, 1..47)
  true
  ```

  ### Remote Types

  Remote types are considered to be a signal that terms in the remote type
  satisfy "special properties".  For example, `t:String.t/0` terms are not
  only binaries, but are UTF-8 encoded binaries.  Thus a remote type is
  considered to be the subtype of its specification, but not vice versa:

  ```elixir
  iex> import Type, only: :macros
  iex> binary = %Type.Bitstring{size: 0, unit: 8}
  iex> Type.subtype?(type(String.t()), binary)
  true
  iex> Type.subtype?(binary, type(String.t()))
  false
  ```
  """
  defdelegate subtype?(type, target), to: Type.Algebra

  @spec union(t, t) :: t
  @spec union([t], preserve_nones: true) :: t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in either type, it is in the result type.
  - if a term is not in either type, it is not in the result type.

  `union/2` will try to collapse types into the simplest representation,
  but the success of this operation is not guaranteed.

  ### Example:
  ```elixir
  iex> import Type, only: :macros
  iex> inspect Type.union(pos_integer(), -10..10)
  "-10..-1 | non_neg_integer()"
  ```
  """
  def union(lst, [preserve_nones: true]), do: upn(lst)
  def union(a, b), do: union([a, b])

  @spec union([t]) :: t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in any of the types, it is in the result type.
  - if a term is not in any type, it is not in the result type.

  `union/1` will try to collapse types into the simplest representation,
  but the success of this operation is not guaranteed.

  If you are in a situation where you would like to explicitly preserve
  the existence of a `none()` type, you can pass `preserve_nones: true`
  to the options list.

  ### Example:
  ```elixir
  iex> import Type, only: :macros
  iex> inspect Type.union([pos_integer(), -10..10, 32, neg_integer()])
  "integer()"
  iex> inspect Type.union([pos_integer(), none()], preserve_nones: true)
  "none() | pos_integer()"
  ```
  """
  def union(types) when is_list(types) do
    types
    |> Enum.reject(&(&1 == none()))
    |> upn
  end

  # helper function (see above:)
  defp upn(types) do
    Enum.into(types, %Type.Union{})
  end

  @spec intersect(t, t) :: t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in both types, it is in the result type.
  - if a term is not in either type, it is not in the result type.

  ### Example:
  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersect(non_neg_integer(), -10..10)
  0..10
  ```
  """
  defdelegate intersect(a, b), to: Type.Algebra

  @spec intersect([Type.t]) :: Type.t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in all of the types in the list, it is in the result type.
  - if a term is not in any of the types in the list, it is not in the result type.

  ### Example:
  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersect([pos_integer(), -1..10, -6..6])
  1..6
  ```
  """
  def intersect([]), do: none()
  def intersect([a]), do: a
  def intersect([a | b]) do
    intersect_helper(a, b)
    Type.intersect(a, Type.intersect(b))
  end

  defp intersect_helper(a, [b]) do
    Type.intersect(a, b)
  end
  defp intersect_helper(a, [b | rest]) do
    intersect_helper(Type.intersect(a, b), rest)
  end

  @spec compare(t, t) :: :lt | :gt | :eq
  @doc """
  Types have an order that facilitates calculation of collapsing values into
  unions.

  Conforms to Elixir's `compare` api, so you can use this in `Enum.sort/2`

  For literals this follows the order in the erlang type system.  Where one
  type is a strict subtype of another, it should wind up less than its supertype

  Types are organized into groups, which exist as a fastlane for comparing
  order between two different types (see `typegroup/1`).

  The order is as follows:
  - group 0: `t:none/0` and remote types
  - group 1 (integers):
    - [negative integer literal]
    - `t:neg_integer/0`
    - [nonnegative integer literal]
    - `t:pos_integer/0`
  - group 2: `t:float/0`
  - group 3 (atoms):
    - [atom literal]
    - `t:node/0`
    - `t:module/0`
    - `t:atom/0`
  - group 4: `t:reference/0`
  - group 5 (`t:Type.Function.t/0`):
    - `params: list` functions (ordered by `retval`, then `params` in dictionary order)
    - `params: :any` functions (ordered by `retval`, then `params` in dictionary order)
  - group 6: `t:port/0`
  - group 7: `t:pid/0`
  - group 8 (`t:Type.Tuple.t/0`):
    - defined tuples, in ascending order of arity, with cartesian
      dictionary ordering intrenally within an arity group.
    - minimum size tuples, in descending order of size.
  - group 9 (`t:Type.Map.t/0`): maps
  - group 10: lists
    - list literals (in erlang term order)
    - `t:Type.List.t/0`
  - group 11 (`t:Type.Bitstring.t/0`): bitstrings and binaries
  - group 12: `t:any/0`

  `t:Range.t/0` (group 1) comes after the highest integer in the range, with
  wider ranges coming after narrower ranges.

  `t:iolist/0` (group 10) comes in the appropriate place in the list group.

  a member of `t:Type.Union.t/0` comes after the highest represented item in its union.

  ## Examples

  ```
  iex> import Type, only: :macros
  iex> Type.compare(integer(), pid())
  :lt
  iex> Type.compare(-5..5, 1..5)
  :gt
  ```
  """
  defdelegate compare(a, b), to: Type.Algebra

  @doc """
  Performs subtraction of types.  The resulting type must comprise all members
  of the first parameter and none of the second.

  ## Examples
  ```
  iex> import Type, only: :macros
  iex> Type.subtract(0..10, 3)
  %Type.Union{of: [4..10, 0..2]}
  iex> Type.subtract(atom(), :foo)
  %Type.Subtraction{base: atom(), exclude: :foo}
  iex> Type.subtract("string", "string")
  none()
  ```
  """
  defdelegate subtract(a, b), to: Type.Algebra

  @typedoc """
  type of group assignments
  """
  @type group :: 0..12

  @doc """
  The typegroup of the type.

  This is a 'fastlane' value which simplifies generating type ordering code.
  See `Type.compare/2` for a list of which groups the types belong to.

  *NB: group assignments may change.*
  """
  @spec typegroup(t) :: group
  defdelegate typegroup(type), to: Type.Algebra

  @spec ternary_and(ternary, ternary) :: ternary
  @doc false
  # ternary and which performs comparisons of ok, maybe, and error
  # types and composes them into the appropriate ternary logic result.
  def ternary_and(:ok, :ok),                        do: :ok
  def ternary_and(:ok, other),                      do: other
  def ternary_and(other, :ok),                      do: other
  def ternary_and({:maybe, left}, {:maybe, right}), do: {:maybe, Enum.uniq(left ++ right)}
  def ternary_and({:maybe, _}, error),              do: error
  def ternary_and(error, {:maybe, _}),              do: error
  def ternary_and(error, _),                        do: error

  @spec ternary_or(ternary, ternary) :: ternary
  @doc false
  # ternary or which performs comparisons of ok, maybe, and error
  # types and composes them into the appropriate ternary logic result.
  def ternary_or(:ok, _),                          do: :ok
  def ternary_or(_, :ok),                          do: :ok
  def ternary_or({:maybe, left}, {:maybe, right}), do: {:maybe, Enum.uniq(left ++ right)}
  def ternary_or({:maybe, left}, _),               do: {:maybe, left}
  def ternary_or(_, {:maybe, right}),              do: {:maybe, right}
  def ternary_or(error, _),                        do: error

  alias Type.Spec

  @doc """
  retrieves a typespec for a function, and converts it to a `t:Type.t/0`
  value.

  ### Example:
  ```elixir
  iex> {:ok, spec} = Type.fetch_spec(String, :split, 1)
  iex> inspect spec
  "(String.t() -> list(String.t()))"
  ```
  """
  def fetch_spec(module, fun, arity) do
    # punt to the Type.SpecInference module to DRY the code up.
    case Type.SpecInference.infer(module, fun, arity) do
      :unknown -> {:error, "spec for #{inspect module}.#{fun}/#{arity} not found"}
      ok_or_error -> ok_or_error
    end
  end

  @spec fetch_type!(Type.t()) :: Type.t() | no_return
  @doc """
  resolves a remote type into its constitutent type.  raises if the type
  is not found.
  """
  def fetch_type!(%Type{module: String, name: :t, params: [size]}) do
    struct(Type.Bitstring, size: 8 * size)
  end
  def fetch_type!(type = %Type{module: module, name: name, params: params})
      when is_remote(type) do
    fetch_type!(module, name, params)
  end

  @spec fetch_type!(module, atom, [Type.t], keyword) :: Type.t | no_return
  @doc """
  see `Type.fetch_type/4`, except raises if the type is not found.
  """
  def fetch_type!(module, name, params \\ [], meta \\ []) do
    case fetch_type(module, name, params, meta) do
      {:ok, specs} -> specs
      {:error, msg} -> raise "#{inspect msg.type} type not found"
    end
  end

  @spec fetch_type(module, atom, [Type.t], keyword) ::
    {:ok, Type.t} | {:error, Type.Message.t}
  @doc """
  retrieves a stored type from a module, and converts it to a `t:Type.t/0`
  value.

  ### Example:
  ```elixir
  iex> {:ok, type} = Type.fetch_type(String, :t)
  iex> inspect type
  "binary()"
  ```

  If the type has non-zero arity, you can specify its passed parameters
  as the third argument.
  """
  def fetch_type(module, name, params \\ [], meta \\ []) do
    with {:ok, specs} <- Code.Typespec.fetch_types(module),
         {type, assignments = %{"$opaque": false}} <-
            find_type(module, specs, name, params) do
      {:ok, Spec.parse(type, assignments)}
    else
      {type, assignments = %{"$opaque": true}} ->
        inner_type = Spec.parse(type, assignments)
        {:ok, struct(Type.Opaque,
          type: inner_type,
          module: module,
          name: name,
          params: params
        )}

      _ -> {:error, struct(Type.Message,
        type: %Type{module: module, name: name, params: params},
        meta: meta ++ [message: "not found"])}
    end
  end

  @prefixes ~w(type typep opaque)a
  defp find_type(module, specs, name, params) do
    arity = length(params)

    Enum.find_value(specs, fn
      {t, {^name, type, tparams}}
          when t in @prefixes and length(tparams) == arity ->
        assignments = tparams
        |> Enum.map(fn {:var, _, key} -> key end)
        |> Enum.zip(params)
        |> Enum.into(%{
          "$mfa": {module, name, arity},
          "$opaque": t == :opaque})
        {type, assignments}
      _ ->
        false
    end)
  end

  @spec type(term) :: Macro.t
  @doc """
  macro wrapper for types which have asts that can't be directly wrapped and
  reinterpreted.

  Examples:

  ```elixir
  iex> import Type
  iex> type(<<>>)
  %Type.Bitstring{size: 0, unit: 0}
  iex> type(( -> any()))
  %Type.Function{branches: [%Type.Function.Branch{params: [], return: any()}]}
  iex> type((... -> any()))
  %Type.Function{branches: [%Type.Function.Branch{params: :any, return: any()}]}
  iex> type((_, _ -> any()))
  %Type.Function{branches: [%Type.Function.Branch{params: 2, return: any()}]}
  ```

  usable in matches.
  """
  defmacro type({:<<>>, _, params}) do
    fields = Enum.map(params, fn
      {:"::", _, [{:_, _, _}, {:*, _, [{:_, _, _}, unit]}]} ->
        {:unit, unit}
      {:"::", _, [{:_, _, _}, size]} ->
        {:size, size}
    end)

    Type.Bitstring
    |> struct(fields)
    |> Macro.escape
  end

  defmacro type([{:->, _, [[{:..., _, [params]}], return]}]) do
    quote do
      %Type.Function{branches: [%Type.Function.Branch{
        params: unquote(params),
        return: unquote(return)
      }]}
    end
  end

  defmacro type([{:->, _, [[{:..., _, _}], return]}]) do
    quote do
      %Type.Function{branches: [%Type.Function.Branch{
        params: :any,
        return: unquote(return)
      }]}
    end
  end

  defmacro type([{:->, _, [params, return]}]) do
    params = cond do
      params == [] -> []
      Enum.all?(params, &match?({:_, _, _}, &1)) ->
        length(params)
      true ->
        Macro.expand(params, __CALLER__)
    end

    quote do
      %Type.Function{branches: [%Type.Function.Branch{
        params: unquote(params),
        return: unquote(return)
      }]}
    end
  end

  defmacro type({:node, _, []}) do
    Macro.escape(%Type{module: nil, name: :node, params: []})
  end

  defmacro type([]), do: []

  defmacro type([{:..., _, a}]) when is_atom(a) do  # note this could be `nil` or `Elixir`
    Macro.escape(%Type.List{type: %Type{module: nil, name: :any, params: []}, final: []})
  end

  defmacro type([t, {:..., _, a}]) when is_atom(a) do
    quote do
      %Type.List{type: unquote(t), final: []}
    end
  end

  defmacro type([{a, t}]) when is_atom(a) do
    quote do
      %Type.Union{of: [%Type.List{type: %Type.Tuple{elements: [unquote(a), unquote(t)], fixed: true}}, []]}
    end
  end

  defmacro type([t]) do
    quote do
      %Type.Union{of: [%Type.List{type: unquote(t), final: []}, []]}
    end
  end

  defmacro type(keyword) when is_list(keyword) do
    if (__CALLER__.context) do
      keyword
      |> Enum.reduce(fn
        {k, _}, _ when not is_atom(k) -> raise "unknown type"
        {k, v}, acc ->
          acc = List.wrap(acc)
          if v in Keyword.values(acc) do
            Enum.map(acc, fn
              {k2, v2} when v2 == v ->
                {Enum.sort([k | List.wrap(k2)], :desc), v}
              other -> other
            end)
          else
            Enum.sort([{k, v} | acc], fn
              {k, _}, {l, _} ->
                [k | _] = List.wrap(k)
                [l | _] = List.wrap(l)
                k > l
            end)
          end
      end)
      |> case do
        [{k, v}] when is_atom(k) ->
          quote do
            %Type.Union{of: [%Type.List{type: unquote(tuple(k, v)), final: []}, []]}
          end
        [{atoms, v}] ->
          k = Macro.escape(%Type.Union{of: atoms})
          quote do
            %Type.Union{of: [%Type.List{type: unquote(tuple(k, v)), final: []}, []]}
          end
        list ->
          kvlist = Enum.map(list, fn
            {k, v} when is_atom(k) -> tuple(k, v)
            {l, v} when is_list(l) -> tuple(Macro.escape(%Type.Union{of: l}), v)
          end)
          quote do
            %Type.Union{of: [%Type.List{type: %Type.Union{of: unquote(kvlist)}, final: []}, []]}
          end
      end
    else
      types = Enum.map(keyword, fn
        {k, _} when not is_atom(k) -> raise "unknown type"
        {k, v} -> quote do %Type.Tuple{elements: [unquote(k), unquote(v)], fixed: true} end
      end)

      quote do
        type([Type.union(unquote(types))])
      end
    end
  end

  defmacro type({:%{}, _, map_ast}) do
    map_as_proplist = map_proplist_from_ast(map_ast)
    quote do
      %Type.Map{
        optional: unquote({:%{}, [], map_as_proplist.optional}),
        required: unquote({:%{}, [], map_as_proplist.required})
      }
    end
  end

  # structs
  defmacro type({:%, _, [{:__aliases__, _, aliases}, {:%{}, _, kvs}]}) do
    module = Module.concat(aliases)

    map_as_proplist = kvs
    |> map_proplist_from_ast()
    |> Map.update(:required, [], fn requireds ->
      requireds = Keyword.put(requireds, :__struct__, module)

      module
      |> struct()
      |> Map.keys()
      |> Enum.reduce(
        requireds,
        &Keyword.put_new(&2, &1, Macro.escape(%Type{module: nil, name: :any, params: []})))
    end)

    quote do
      %Type.Map{
        optional: unquote({:%{}, [], map_as_proplist.optional}),
        required: unquote({:%{}, [], map_as_proplist.required})
      }
    end
  end

  defmacro type({:{}, _, contents}) do
    tuple = Enum.reduce(contents, %{elements: [], fixed: true}, fn
      {:..., _, _}, acc ->
        %{acc | fixed: false}
      t, acc ->
        %{acc | elements: acc.elements ++ [t]}
    end)

    quote do
      %Type.Tuple{elements: unquote(tuple.elements), fixed: unquote(tuple.fixed)}
    end
  end

  defmacro type({a, {:..., _, _}}) do
    quote do
      %Type.Tuple{elements: [unquote(a)], fixed: false}
    end
  end

  defmacro type({a, b}) do
    quote do
      %Type.Tuple{elements: unquote([a, b]), fixed: true}
    end
  end

  # remote types
  defmacro type({{:., _, [module, name]}, _, params}) do
    case module do
      {:__aliases__, _, [:String]} ->
        quote do
          %Type.Bitstring{
            size: 0,
            unit: 8,
            unicode: true
          }
        end
      {:__aliases__, _, aliases} ->
        quote do
          %Type{
            module: unquote(Module.concat(aliases)),
            name: unquote(name),
            params: unquote(params)
          }
        end
      module when is_atom(module) ->
        quote do
          %Type{
            module: unquote(module),
            name: unquote(name),
            params: unquote(params)
          }
        end
    end
  end

  defmacro type(_other) do
    raise "unknown type"
  end

  defmacro opaque({{:., _, [{:__aliases__, _, modpath}, name]}, _, params}, type) do
    module = Module.concat(modpath)
    quote do
      %Type.Opaque{
        module: unquote(module),
        name: unquote(name),
        params: unquote(params),
        type: unquote(type)}
    end
  end

  defp map_proplist_from_ast(map_ast) do
    map_ast
    |> Enum.group_by(fn
      {{:required, _, _}, _} -> :required
      {{:optional, _, _}, _} -> :optional
      {k, _} when is_atom(k) or is_integer(k) -> :required
      _ -> :optional
    end, fn
      {{:required, _, [k]}, v} -> {k, v}
      {{:optional, _, [k]}, v} -> {k, v}
      kv -> kv
    end)
    |> Map.put_new(:required, [])
    |> Map.put_new(:optional, [])
  end

  defp tuple(k, v) do
    quote do %Type.Tuple{elements: [unquote(k), unquote(v)], fixed: true} end
  end

  @spec of(term) :: Type.t
  @doc """
  returns the type of the term.

  ### Examples:
  ```
  iex> Type.of(47)
  47
  iex> inspect Type.of(47.0)
  "float()"
  iex> inspect Type.of([:foo, :bar])
  "list(:bar | :foo, ...)"
  iex> inspect Type.of([:foo | :bar])
  "nonempty_improper_list(:foo, :bar)"
  ```

  Note that for functions, this may not be correct unless you
  supply an inference engine (see `Type.Function`):

  ```
  iex> inspect Type.of(&(&1 + 1))
  "(any() -> any())"
  ```

  For maps, atom and number literals are marshalled into required
  terms; other literals, like strings, are marshalled into optional
  terms.

  ```
  iex> inspect Type.of(%{foo: :bar})
  "type(%{foo: :bar})"
  iex> inspect Type.of(%{1 => :one})
  "type(%{1 => :one})"
  iex> inspect Type.of(%{"foo" => :bar, "baz" => "quux"})
  "type(%{optional(String.t()) => :bar | String.t()})"
  iex> inspect Type.of(1..10)
  "type(%Range{first: 1, last: 10})"
  ```
  """
  def of(value)
  def of(integer) when is_integer(integer), do: integer
  def of(float) when is_float(float), do: float
  def of(atom) when is_atom(atom), do: atom
  def of(reference) when is_reference(reference), do: reference()
  def of(port) when is_port(port), do: port()
  def of(pid) when is_pid(pid), do: pid()
  def of(bitstring) when is_bitstring(bitstring), do: bitstring
  def of(tuple) when is_tuple(tuple) do
    types = tuple
    |> Tuple.to_list()
    |> Enum.map(&Type.of/1)

    %Type.Tuple{elements: types}
  end
  def of([]), do: []
  def of([head | rest]) do
    of_list(rest, Type.of(head))
  end
  def of(map) when is_map(map) do
    map
    |> Map.keys
    |> Enum.map(&{&1, Type.of(&1)})
    |> Enum.reduce(struct(Type.Map), fn
      {key, _}, acc when is_integer(key) or is_atom(key) ->
        val_type = map
        |> Map.get(key)
        |> Type.of

        %{acc | required: Map.put(acc.required, key, val_type)}
      {key, key_type}, acc ->
        val_type = map
        |> Map.get(key)
        |> Type.of

        updated_val_type = if is_map_key(acc.optional, key_type) do
          acc.optional
          |> Map.get(key_type)
          |> Type.union(val_type)
        else
          val_type
        end

        %{acc | optional: Map.put(acc.optional, key_type, updated_val_type)}
    end)
  end
  def of(lambda) when is_function(lambda) do
    inference_module = Application.get_env(:mavis, :inference, Type.NoInference)

    [module, fun, arity, _env] = lambda
    |> :erlang.fun_info
    |> Keyword.take([:module, :name, :arity, :env])
    |> Keyword.values()

    case inference_module.infer(module, fun, arity) do
      {:ok, type} -> type
      _ -> raise "error finding type"
    end
  end

  defp of_list([head | rest], so_far) do
    of_list(rest, Type.union(Type.of(head), so_far))
  end
  defp of_list([], so_far) do
    %Type.List{type: so_far}
  end
  defp of_list(non_list, so_far) do
    %Type.List{type: so_far, final: Type.of(non_list)}
  end

  @spec type_match?(t, term) :: boolean
  @doc """
  true if the passed term is an element of the type.

  ## Important:
  Note the argument order for this function, it does not have the
  same call order, as say, JavaScript's `instanceof`, or ruby's `.is_a?`

  ### Example:
  ```elixir
  iex> import Type, only: :macros
  iex> Type.type_match?(integer(), 10)
  true
  iex> Type.type_match?(neg_integer(), 10)
  false
  iex> Type.type_match?(pos_integer(), 10)
  true
  iex> Type.type_match?(1..9, 10)
  false
  iex> Type.type_match?(-47..47, 10)
  true
  iex> Type.type_match?(42, 10)
  false
  iex> Type.type_match?(10, 10)
  true
  ```
  """
  def type_match?(type, term) do
    term
    |> of
    |> subtype?(type)
  end

  @spec partition(t, [t]) :: [t]
  @doc """
  partitions a type across a list of types

  see https://en.wikipedia.org/wiki/Partition_of_a_set

  note however, that if some part of your type is not represented
  in the type list that is provided, those members will be discarded.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.partition(-5..5, integer().of)
  [1..5, 0, -5..-1]
  ```
  """
  def partition(type, type_list) when is_list(type_list) do
    Enum.map(type_list, &Type.intersect(type, &1))
  end

  @spec covered?(t, [t]) :: boolean
  @doc """
  true if the list of types constitutes a complete cover of the
  provided type.

  see https://en.wikipedia.org/wiki/Cover_(topology)

  ```elixir
  iex> Type.covered?(-5..5, [1..5, 0, -5..-1])
  true
  iex> Type.covered?(-5..5, [1..5, 0, -5..-2])
  false
  ```
  """
  def covered?(type, type_list) when is_list(type_list) do
    Type.subtype?(type, Type.union(type_list))
  end

  defdelegate normalize(type), to: Type.Algebra
end

defimpl Inspect, for: Type do
  import Inspect.Algebra

  def inspect(%{module: nil, name: name, params: params}, opts) do
    param_list = params
    |> Enum.map(&to_doc(&1, opts))
    |> Enum.intersperse(", ")
    |> concat

    concat(["#{name}(", param_list, ")"])
  end
  def inspect(%{module: module, name: name, params: params}, opts) do
    param_list = params
    |> Enum.map(&to_doc(&1, opts))
    |> Enum.intersperse(", ")
    |> concat

    concat([to_doc(module, opts), ".#{name}(", param_list, ")"])
  end
end
