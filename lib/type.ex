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
  iex> inspect Type.union(builtin(:non_neg_integer), :infinity)
  "timeout()"
  iex> Type.intersection(builtin(:pos_integer), -10..10)
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
  - `Type.intersection/1`
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

  The nonexistent type `String.t/1` is also implemented, with the type
  parameter indicating byte-lengths for compile-time constant strings.
  This is done entirely under the hood and should not otherwise affect
  operations.  If you encounter strange results, report them to the issue
  tracker.

  In the meantime, you may disable this feature by setting the following:

  ```elixir
  config :mavis, :use_smart_strings, false
  ```

  ### "Aliased builtins"

  Some builtins were not directly introduced into the typesystem logic, since
  they are easily represented as aliases or composite types.  The following
  aliased builtins are usable with the `builtin/1` macro, but will return false
  with `is_builtin/1`

  **NB in the future the name of `is_builtin` may change to prevent confusion.**

  - `t:term/0`
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
  iex> import Type
  iex> builtin(:timeout)
  %Type.Union{of: [:infinity, %Type{name: :non_neg_integer}]}
  iex> Type.is_builtin(builtin(:timeout))
  false
  ```

  ### Module and Node detail

  The `t:module/0` and `t:node/0` types are given extra protection.

  An atom will not be considered a module unless it is detected to exist
  in the VM; although for `usable_as/3` it will return the `:maybe` result
  if unconfirmed.

  ```elixir
  iex> import Type
  iex> Type.type_match?(builtin(:module), :foo)
  false
  iex> Type.type_match?(builtin(:module), Kernel)
  true
  iex> Type.type_match?(builtin(:module), :gen_server)
  true
  iex> Type.usable_as(Enum, builtin(:module))
  :ok
  iex> Type.usable_as(:not_a_module, builtin(:module))
  {:maybe, [%Type.Message{target: %Type{name: :module}, type: :not_a_module}]}
  ```

  A node will not be considered a node unless it has the proper form for a
  node.  `usable_as/3` does not check active node lists, however.

  ```elixir
  iex> import Type
  iex> Type.type_match?(builtin(:node), :foo)
  false
  iex> Type.type_match?(builtin(:node), :nonode@nohost)
  true
  ```
  """

  @enforce_keys [:name]
  defstruct @enforce_keys ++ [:module, params: []]

  @type t :: %__MODULE__{
    name: atom,
    module: nil | module,
    params: [t]
  } | integer | Range.t | atom
  #| Type.AsBoolean.t
  | Type.List.t | []
  | Type.Bitstring.t
  | Type.Tuple.t
  | Type.Map.t
  | Type.Function.t
  | Type.Union.t
  | Type.Opaque.t
  | Type.Function.Var.t

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

  @primitive_builtins [
    :none, :neg_integer, :pos_integer, :non_neg_integer, :integer,
    :float, :node, :module, :atom, :reference, :port, :pid, :iolist,
    :any]

  @spec builtin(atom) :: Macro.t
  @doc """
  helper macro to  match on builtin types.

  ### Example:
  ```elixir
  iex> Type.builtin(:integer)
  %Type{name: :integer}
  ```

  *Usable in guards*
  """
  defmacro builtin(:term) do
    quote do %Type{module: nil, name: :any, params: []} end
  end
  defmacro builtin(arity_or_byte) when arity_or_byte in [:arity, :byte] do
    quote do 0..255 end
  end
  defmacro builtin(:binary) do
    quote do %Type.Bitstring{size: 0, unit: 8} end
  end
  defmacro builtin(:bitstring) do
    quote do %Type.Bitstring{size: 0, unit: 1} end
  end
  defmacro builtin(:boolean) do
    quote do %Type.Union{of: [true, false]} end
  end
  defmacro builtin(:char) do
    quote do 0..0x10_FFFF end
  end
  defmacro builtin(:charlist) do
    quote do %Type.List{type: 0..0x10_FFFF, nonempty: false, final: []} end
  end
  defmacro builtin(:nonempty_charlist) do
    quote do %Type.List{type: 0..0x10_FFFF, nonempty: true, final: []} end
  end
  defmacro builtin(fun) when fun in [:fun, :function] do
    quote do %Type.Function{params: :any, return: %Type{module: nil, name: :any, params: []}} end
  end
  defmacro builtin(:identifier) do
    quote do
      %Type.Union{of:
      [%Type{module: nil, name: :pid, params: []},
       %Type{module: nil, name: :port, params: []},
       %Type{module: nil, name: :reference, params: []}]}
    end
  end
  defmacro builtin(:iodata) do
    quote do
      %Type.Union{of:
      [%Type.Bitstring{size: 0, unit: 8},
       %Type{module: nil, name: :iolist, params: []}]}
    end
  end
  defmacro builtin(:keyword) do
    quote do
      %Type.List{type:
        %Type.Tuple{elements: [%Type{module: nil, name: :atom, params: []},
                               %Type{module: nil, name: :any, params: []}]}}
    end
  end
  defmacro builtin(:list) do
    quote do
      %Type.List{type: %Type{module: nil, name: :any, params: []}}
    end
  end
  defmacro builtin(:nonempty_list) do
    quote do
      %Type.List{type: %Type{module: nil, name: :any, params: []}, nonempty: true}
    end
  end
  defmacro builtin(:maybe_improper_list) do
    quote do
      %Type.List{
        type: %Type{module: nil, name: :any, params: []},
        final: %Type{module: nil, name: :any, params: []}}
    end
  end
  defmacro builtin(:nonempty_maybe_improper_list) do
    quote do
      %Type.List{
        type: %Type{module: nil, name: :any, params: []},
        nonempty: true,
        final: %Type{module: nil, name: :any, params: []}}
    end
  end
  defmacro builtin(:mfa) do
    quote do
      %Type.Tuple{elements: [
        %Type{module: nil, name: :module, params: []},
        %Type{module: nil, name: :atom, params: []},
        0..255
      ]}
    end
  end
  defmacro builtin(:no_return) do
    quote do %Type{module: nil, name: :none, params: []} end
  end
  defmacro builtin(:number) do
    quote do
      %Type.Union{of: [
        %Type{module: nil, name: :float, params: []},
        %Type{module: nil, name: :integer, params: []},
      ]}
    end
  end
  defmacro builtin(:struct) do
    quote do
      %Type.Map{required: %{__struct__: %Type{module: nil, params: [], name: :atom}},
                optional: %{%Type{module: nil, params: [], name: :atom} =>
                            %Type{module: nil, params: [], name: :any}}}
    end
  end
  defmacro builtin(:timeout) do
    quote do
      %Type.Union{of: [
        :infinity,
        %Type{module: nil, name: :non_neg_integer, params: []},
      ]}
    end
  end
  defmacro builtin(type) when
    not is_atom(type) or type in @primitive_builtins do
    quote do %Type{module: nil, name: unquote(type), params: []} end
  end

  @spec remote(Macro.t) :: Macro.t
  @doc """
  helper macro to match on remote types

  ### Example:
  ```elixir
  iex> Type.remote(String.t())
  %Type{module: String, name: :t}
  ```
  """
  defmacro remote({{:., _, [module_ast, name]}, _, atom}) when is_atom(atom) do
    Macro.escape(%Type{module: module_ast, name: name})
  end
  defmacro remote({{:., _, [module_ast, name]}, _, params_ast}) do
    params = Enum.map(params_ast, fn ast ->
      quote do
        remote(unquote(ast))
      end
    end)
    quote do
      %Type{module: unquote(module_ast),
            name: unquote(name),
            params: unquote(params)}
    end
  end
  defmacro remote(ast = {builtin, _, atom}) when is_atom(atom) do
    # detect if we're trying to be a variable or if we're trying
    # to call a zero-arity builtin.
    __CALLER__.current_vars
    |> elem(0)
    |> Enum.any?(&match?({{^builtin, _}, _}, &1))
    |> if do
      ast
    else
      Macro.escape(%Type{module: nil, name: builtin, params: []})
    end
  end
  defmacro remote({builtin, _, params}) do
    Macro.escape(%Type{module: nil, name: builtin, params: params})
  end
  defmacro remote(any) do
    quote do unquote(any) end
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
  defguard is_remote(type) when is_struct(type) and
    :erlang.map_get(:__struct__, type) == Type and
    :erlang.map_get(:module, type) != nil

  @doc """
  guard that tests if the selected type is builtin

  ### Example:
  ```
  iex> Type.is_builtin(:foo)
  false
  iex> Type.is_builtin(%Type{name: :integer})
  true
  iex> Type.is_builtin(%Type{module: String, name: :t})
  false
  ```

  Note that composite builtin types may not match with this
  function:

  ```
  iex> import Type
  iex> Type.is_builtin(builtin(:mfa))
  false
  ```
  """
  defguard is_builtin(type) when is_struct(type) and
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

  ### Relationship to `subtype/2`

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
  iex> import Type
  iex> Type.usable_as(1, builtin(:integer))
  :ok
  iex> Type.usable_as(1, builtin(:neg_integer))
  {:error, %Type.Message{type: 1, target: builtin(:neg_integer)}}
  iex> Type.usable_as(-10..10, builtin(:neg_integer))
  {:maybe, [%Type.Message{type: -10..10, target: builtin(:neg_integer)}]}
  ```

  ### Remote types:

  A remote type is intended to indicate that there is a quality outside of
  the type system which specifies the type.  Thus, a remote type should
  be usable as the type it encapsulates, but it should emit a `maybe` when
  going the other direction:

  ```
  iex> import Type
  iex> binary = %Type.Bitstring{size: 0, unit: 8}
  iex> Type.usable_as(remote(String.t()), binary)
  :ok
  iex> Type.usable_as(binary, remote(String.t))
  {:maybe, [%Type.Message{
              type: binary,
              target: remote(String.t()),
              meta: [message: \"""
    binary() is an equivalent type to String.t() but it may fail because it is
    a remote encapsulation which may require qualifications outside the type system.
    \"""]}]}
  ```
  """
  defdelegate usable_as(challenge, target, meta \\ []), to: Type.Properties

  @spec subtype?(t, t) :: boolean
  @doc """
  outputs whether one type is a subtype of itself.  To be true, the
  following condition must be satisfied:

  - if a term is in the first type, then it is also in the second type.

  Note that any type is automatically a subtype of itself.

  ### Examples:

  ```elixir
  iex> import Type
  iex> Type.subtype?(10, 1..47)
  true
  iex> Type.subtype?(10, builtin(:integer))
  true
  iex> Type.subtype?(1..47, builtin(:integer))
  true
  iex> Type.subtype?(builtin(:integer), 1..47)
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
  iex> import Type
  iex> binary = %Type.Bitstring{size: 0, unit: 8}
  iex> Type.subtype?(remote(String.t()), binary)
  true
  iex> Type.subtype?(binary, remote(String.t()))
  false
  ```
  """
  defdelegate subtype?(type, target), to: Type.Properties

  @spec union(t, t) :: t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in either type, it is in the result type.
  - if a term is not in either type, it is not in the result type.

  `union/2` will try to collapse types into the simplest representation,
  but the success of this operation is not guaranteed.

  ### Example:
  ```elixir
  iex> import Type
  iex> inspect Type.union(builtin(:non_neg_integer), -10..10)
  "-10..-1 | non_neg_integer()"
  ```
  """
  def union(a, b), do: union([a, b])

  @spec union([t]) :: t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in any of the types, it is in the result type.
  - if a term is not in any type, it is not in the result type.

  `union/1` will try to collapse types into the simplest representation,
  but the success of this operation is not guaranteed.

  ### Example:
  ```elixir
  iex> import Type
  iex> inspect Type.union([builtin(:pos_integer), -10..10, 32, builtin(:neg_integer)])
  "integer()"
  ```
  """
  def union(types) when is_list(types) do
    Enum.into(types, struct(Type.Union))
  end

  @spec intersection(t, t) :: t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in both types, it is in the result type.
  - if a term is not in either type, it is not in the result type.

  ### Example:
  ```elixir
  iex> import Type
  iex> Type.intersection(builtin(:non_neg_integer), -10..10)
  0..10
  ```
  """
  defdelegate intersection(a, b), to: Type.Properties

  @spec intersection([Type.t]) :: Type.t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in all of the types in the list, it is in the result type.
  - if a term is not in any of the types in the list, it is not in the result type.

  ### Example:
  ```elixir
  iex> import Type
  iex> Type.intersection([builtin(:pos_integer), -1..10, -6..6])
  1..6
  ```
  """
  def intersection([]), do: builtin(:none)
  def intersection([a]), do: a
  def intersection([a | b]) do
    Type.intersection(a, Type.intersection(b))
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
    - `t:non_neg_integer/0`
    - `t:integer/0`
  - group 2: `t:float/0`
  - group 3 (atoms):
    - [atom literal]
    - `t:node/0`
    - `t:module/0`
    - `t:atom/0`
  - group 4: `t:reference/0`
  - group 5 (`t:Type.List.t/0`):
    - `params: list` functions (ordered by `retval`, then `params` in dictionary order)
    - `params: :any` functions (ordered by `retval`, then `params` in dictionary order)
  - group 6: `t:port/0`
  - group 7: `t:pid/0`
  - group 8 (`t:Type.Tuple.t/0`):
    - defined arity tuple
    - any tuple
  - group 9 (`t:Type.Map.t/0`): maps
  - group 10 (`t:Type.List.t/0`):
    - `nonempty: true` list
    - empty list literal
    - `nonempty: false` lists
  - group 11 (`t:Type.Bitstring.t/0`): bitstrings and binaries
  - group 12: `t:any/0`

  `t:Range.t/0` (group 1) comes after the highest integer in the range, with
  wider ranges coming after narrower ranges.

  `t:iolist/0` (group 10) comes in the appropriate place in the list group.

  a member of `t:Type.Union.t/0` comes after the highest represented item in its union.

  ## Examples

  ```
  iex> import Type, only: :macros
  iex> Type.compare(builtin(:integer), builtin(:pid))
  :lt
  iex> Type.compare(-5..5, 1..5)
  :gt
  ```

  """
  defdelegate compare(a, b), to: Type.Properties

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
  defdelegate typegroup(type), to: Type.Properties

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
  "(String.t() -> [String.t()])"
  ```
  """
  def fetch_spec(module, fun, arity) do
    with {:module, _} <- Code.ensure_loaded(module),
         {:ok, specs} <- Code.Typespec.fetch_specs(module),
         spec when spec != nil <- find_spec(module, specs, fun, arity) do
      {:ok, spec}
    else
      :error ->
        {:error, "this module was not found"}
      nil ->
        # note that we might be trying to find information for
        # a lambda, which won't necessarily be directly exported.
        :unknown
      error -> error
    end
  end

  defp find_spec(module, specs, fun, arity) do
    Enum.find_value(specs, fn
      {{^fun, ^arity}, specs_for_mfa} ->
        specs_for_mfa
        |> Enum.map(&Spec.parse(&1, %{"$mfa": {module, fun, arity}}))
        |> union
      _ -> false
    end)
  end

  @spec fetch_type!(Type.t()) :: Type.t() | no_return
  @doc """
  resolves a remote type into its constitutent type.  raises if the type
  is not found.
  """
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
  "[:bar | :foo, ...]"
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
  "%{foo: :bar}"
  iex> inspect Type.of(%{1 => :one})
  "%{required(1) => :one}"
  iex> inspect Type.of(%{"foo" => :bar, "baz" => "quux"})
  "%{optional(String.t()) => :bar | String.t()}"
  iex> inspect Type.of(1..10)
  "%Range{first: 1, last: 10}"
  ```
  """
  def of(value)
  def of(integer) when is_integer(integer), do: integer
  def of(float) when is_float(float), do: builtin(:float)
  def of(atom) when is_atom(atom), do: atom
  def of(reference) when is_reference(reference), do: builtin(:reference)
  def of(port) when is_port(port), do: builtin(:port)
  def of(pid) when is_pid(pid), do: builtin(:pid)
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
          |> Type.Union.of(val_type)
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
  def of(bitstring) when is_bitstring(bitstring) do
    of_bitstring(bitstring)
  end

  defp of_list([head | rest], so_far) do
    of_list(rest, Type.Union.of(Type.of(head), so_far))
  end
  defp of_list([], so_far) do
    %Type.List{type: so_far, nonempty: true}
  end
  defp of_list(non_list, so_far) do
    %Type.List{type: so_far, nonempty: true, final: Type.of(non_list)}
  end

  defp of_bitstring(bitstring, bits_so_far \\ 0)
  defp of_bitstring(<<>>, 0), do: %Type.Bitstring{size: 0, unit: 0}
  defp of_bitstring(<<>>, bits) do
    if Application.get_env(:mavis, :use_smart_strings, true) do
      bytes = div(bits, 8)
      remote(String.t(bytes))
    else
      remote(String.t)
    end
  end
  defp of_bitstring(<<0::1, chr::7, rest :: binary>>, so_far) when chr != 0 do
    of_bitstring(rest, so_far + 8)
  end
  defp of_bitstring(<<6::3, _::5, 2::2, _::6, rest :: binary>>, so_far) do
    of_bitstring(rest, so_far + 16)
  end
  defp of_bitstring(<<14::4, _::4, 2::2, _::6, 2::2, _::6, rest::binary>>, so_far) do
    of_bitstring(rest, so_far + 24)
  end
  defp of_bitstring(<<30::5, _::3, 2::2, _::6, 2::2, _::6, 2::2, _::6, rest::binary>>, so_far) do
    of_bitstring(rest, so_far + 32)
  end
  defp of_bitstring(bitstring, so_far) do
    %Type.Bitstring{size: bit_size(bitstring) + so_far, unit: 0}
  end

  @spec type_match?(t, term) :: boolean
  @doc """
  true if the passed term is an element of the type.

  ## Important:
  Note the argument order for this function, it does not have the
  same call order, as say, JavaScript's `instanceof`, or ruby's `.is_a?`

  ### Example:
  ```elixir
  iex> import Type
  iex> Type.type_match?(builtin(:integer), 10)
  true
  iex> Type.type_match?(builtin(:neg_integer), 10)
  false
  iex> Type.type_match?(builtin(:pos_integer), 10)
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
end

defimpl Type.Properties, for: Type do
  # LUT for builtin types groups.
  @groups_for %{
    none: 0, neg_integer: 1, non_neg_integer: 1, pos_integer: 1, integer: 1,
    float: 2, node: 3, module: 3, atom: 3, reference: 4, port: 6, pid: 7,
    iolist: 10, any: 12}

  import Type, only: :macros

  import Type.Helpers

  alias Type.Message

  usable_as do
    def usable_as(challenge, target = %Type{module: String, name: :t}, meta) do
      usable_as_string(challenge, target, meta)
    end
    def usable_as(challenge = %Type{module: String, name: :t}, target, meta) do
      string_usable_as(challenge, target, meta)
    end

    def usable_as(challenge, target, meta) when is_remote(challenge) do
      challenge
      |> Type.fetch_type!()
      |> Type.usable_as(target, meta)
    end

    # negative integer
    def usable_as(builtin(:neg_integer), builtin(:integer), _meta), do: :ok

    def usable_as(builtin(:neg_integer), a, meta) when is_integer(a) and a < 0 do
      {:maybe, [Message.make(builtin(:neg_integer), a, meta)]}
    end
    def usable_as(builtin(:neg_integer), a..b, meta) when a < 0 do
      {:maybe, [Message.make(builtin(:neg_integer), a..b, meta)]}
    end

    # non negative integer
    def usable_as(builtin(:non_neg_integer), builtin(:integer), _meta), do: :ok

    def usable_as(builtin(:non_neg_integer), builtin(:pos_integer), meta) do
      {:maybe, [Message.make(builtin(:non_neg_integer), builtin(:pos_integer), meta)]}
    end
    def usable_as(builtin(:non_neg_integer), a, meta) when is_integer(a) and a >= 0 do
      {:maybe, [Message.make(builtin(:non_neg_integer), a, meta)]}
    end
    def usable_as(builtin(:non_neg_integer), a..b, meta) when b >= 0 do
      {:maybe, [Message.make(builtin(:non_neg_integer), a..b, meta)]}
    end

    # positive integer
    def usable_as(builtin(:pos_integer), builtin(target), _meta)
      when target in [:non_neg_integer, :integer], do: :ok

    def usable_as(builtin(:pos_integer), a, meta) when is_integer(a) and a > 0 do
      {:maybe, [Message.make(builtin(:pos_integer), a, meta)]}
    end
    def usable_as(builtin(:pos_integer), a..b, meta) when b > 0 do
      {:maybe, [Message.make(builtin(:pos_integer), a..b, meta)]}
    end

    # integer
    def usable_as(builtin(:integer), builtin(target), meta)
      when target in [:neg_integer, :non_neg_integer, :pos_integer] do
        {:maybe, [Message.make(builtin(:integer), builtin(target), meta)]}
    end

    def usable_as(builtin(:integer), a, meta) when is_integer(a) do
      {:maybe, [Message.make(builtin(:integer), a, meta)]}
    end
    def usable_as(builtin(:integer), a..b, meta) do
      {:maybe, [Message.make(builtin(:integer), a..b, meta)]}
    end

    # atom
    def usable_as(builtin(:node), builtin(:atom), _meta), do: :ok
    def usable_as(builtin(:node), atom, meta) when is_atom(atom) do
      if valid_node?(atom) do
        {:maybe, [Message.make(builtin(:node), atom, meta)]}
      else
        {:error, Message.make(builtin(:node), atom, meta)}
      end
    end
    def usable_as(builtin(:module), builtin(:atom), _meta), do: :ok
    def usable_as(builtin(:module), atom, meta) when is_atom(atom) do
      # TODO: consider elaborating on this and making more specific
      # warning messages for when the module is or is not detected.
      {:maybe, [Message.make(builtin(:module), atom, meta)]}
    end
    def usable_as(builtin(:atom), builtin(:node), meta) do
      {:maybe, [Message.make(builtin(:atom), builtin(:node), meta)]}
    end
    def usable_as(builtin(:atom), builtin(:module), meta) do
      {:maybe, [Message.make(builtin(:atom), builtin(:module), meta)]}
    end
    def usable_as(builtin(:atom), atom, meta) when is_atom(atom) do
      {:maybe, [Message.make(builtin(:atom), atom, meta)]}
    end

    # iolist
    def usable_as(builtin(:iolist), [], meta) do
      {:maybe, [Message.make(builtin(:iolist), [], meta)]}
    end
    def usable_as(builtin(:iolist), list = %Type.List{}, meta) do
      Type.Iolist.usable_as_list(list, meta)
    end

    # any
    def usable_as(builtin(:any), any_other_type, meta) do
      {:maybe, [Message.make(builtin(:any), any_other_type, meta)]}
    end
  end

  defp usable_as_string(%Type{module: String, name: :t}, %{params: []}, _meta), do: :ok
  defp usable_as_string(challenge = %Type{module: String, name: :t, params: []},
                        target = %{params: [_t]}, meta) do
    {:maybe, [Message.make(challenge, target, meta)]}
  end
  defp usable_as_string(challenge = %Type{module: String, name: :t, params: [pl]},
                        target = %{params: [pr]}, meta) do
    cond do
      Type.subtype?(pl, pr) -> :ok
      Type.subtype?(pr, pl) -> {:maybe, [Message.make(challenge, target, meta)]}
      true -> {:error, Message.make(challenge, target, meta)}
    end
  end
  defp usable_as_string(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end

  defp string_usable_as(%{params: []}, target, meta) do
    Type.usable_as(builtin(:binary), target, meta)
  end
  defp string_usable_as(%{params: [size]}, target, meta) when is_integer(size) do
    Type.usable_as(%Type.Bitstring{size: size * 8}, target, meta)
  end
  defp string_usable_as(%{params: [%Type.Union{of: ints}]}, target, meta) do
    ints
    |> Enum.map(&Type.usable_as(%Type.Bitstring{size: &1 * 8}, target, meta))
    |> Enum.reduce(&Type.ternary_and/2)
  end


  intersection do
    # negative integer
    def intersection(builtin(:neg_integer), builtin(:integer)), do: builtin(:neg_integer)
    def intersection(builtin(:neg_integer), a) when is_integer(a) and a < 0, do: a
    def intersection(builtin(:neg_integer), a..b) when b < 0, do: a..b
    def intersection(builtin(:neg_integer), -1.._), do: -1
    def intersection(builtin(:neg_integer), a.._) when a < 0, do: a..-1
    # positive integer
    def intersection(builtin(:pos_integer), builtin(:integer)), do: builtin(:pos_integer)
    def intersection(builtin(:pos_integer), builtin(:non_neg_integer)), do: builtin(:pos_integer)
    def intersection(builtin(:pos_integer), a) when is_integer(a) and a > 0, do: a
    def intersection(builtin(:pos_integer), a..b) when a > 0, do: a..b
    def intersection(builtin(:pos_integer), _..1), do: 1
    def intersection(builtin(:pos_integer), _..b) when b > 0, do: 1..b
    # non negative integer
    def intersection(builtin(:non_neg_integer), builtin(:integer)), do: builtin(:non_neg_integer)
    def intersection(builtin(:non_neg_integer), builtin(:pos_integer)), do: builtin(:pos_integer)
    def intersection(builtin(:non_neg_integer), a) when is_integer(a) and a >= 0, do: a
    def intersection(builtin(:non_neg_integer), a..b) when a >= 0, do: a..b
    def intersection(builtin(:non_neg_integer), _..0), do: 0
    def intersection(builtin(:non_neg_integer), _..b) when b >= 0, do: 0..b
    # general integers
    def intersection(builtin(:integer), a) when is_integer(a), do: a
    def intersection(builtin(:integer), a..b), do: a..b
    def intersection(builtin(:integer), builtin(:neg_integer)), do: builtin(:neg_integer)
    def intersection(builtin(:integer), builtin(:pos_integer)), do: builtin(:pos_integer)
    def intersection(builtin(:integer), builtin(:non_neg_integer)), do: builtin(:non_neg_integer)
    # atoms
    def intersection(builtin(:node), atom) when is_atom(atom) do
      if valid_node?(atom), do: atom, else: builtin(:none)
    end
    def intersection(builtin(:node), builtin(:atom)), do: builtin(:node)
    def intersection(builtin(:module), atom) when is_atom(atom) do
      if valid_module?(atom), do: atom, else: builtin(:none)
    end
    def intersection(builtin(:module), builtin(:atom)), do: builtin(:module)
    def intersection(builtin(:atom), builtin(:module)), do: builtin(:module)
    def intersection(builtin(:atom), builtin(:node)), do: builtin(:node)
    def intersection(builtin(:atom), atom) when is_atom(atom), do: atom
    # iolist
    def intersection(builtin(:iolist), any), do: Type.Iolist.intersection_with(any)

    # strings
    def intersection(remote(String.t), target = %Type{module: String, name: :t}), do: target
    def intersection(target = %Type{module: String, name: :t}, remote(String.t)), do: target
    def intersection(%Type{module: String, name: :t, params: [lp]},
                     %Type{module: String, name: :t, params: [rp]}) do
      case Type.intersection(lp, rp) do
        builtin(:none) -> builtin(:none)
        int_type -> %Type{module: String, name: :t, params: [int_type]}
      end
    end
    def intersection(%Type{module: String, name: :t, params: [lp]}, bs = %Type.Bitstring{}) do
      lp
      |> case do
        i when is_integer(i) ->
          if sized?(i, bs), do: [i], else: []
        range = _.._ ->
          Enum.filter(range, &sized?(&1, bs))
        %Type.Union{of: ints} ->
          Enum.filter(ints, &sized?(&1, bs))
      end
      |> case do
        [] -> builtin(:none)
        lst -> %Type{module: String, name: :t, params: [Enum.into(lst, %Type.Union{})]}
      end
    end

    # remote types
    def intersection(type = %Type{module: module, name: name, params: params}, right)
        when is_remote(type) do
      # deal with errors later.
      # TODO: implement type caching system
      left = Type.fetch_type!(module, name, params)
      Type.intersection(left, right)
    end
  end

  def sized?(i, %{size: size}) when (i * 8) < size, do: false
  def sized?(i, %{size: size, unit: 0}), do: i * 8 == size
  def sized?(i, %{size: size, unit: unit}), do: rem(i * 8 - size, unit) == 0

  def valid_node?(atom) do
    atom
    |> Atom.to_string
    |> String.split("@")
    |> case do
      [_, _] -> true
      _ -> false
    end
  end

  def valid_module?(atom) do
    function_exported?(atom, :module_info, 0)
  end

  def typegroup(%{module: nil, name: name}) do
    @groups_for[name]
  end
  # String.t is special-cased.
  def typegroup(%{module: String, name: :t}), do: 11
  def typegroup(_type), do: 0

  def compare(this, other) do
    this_group = Type.typegroup(this)
    other_group = Type.typegroup(other)
    cond do
      this_group > other_group -> :gt
      this_group < other_group -> :lt
      true -> group_compare(this, other)
    end
  end

  group_compare do
    # group compare for the integer block.
    def group_compare(builtin(:integer), _),               do: :gt
    def group_compare(_, builtin(:integer)),               do: :lt
    def group_compare(builtin(:non_neg_integer), _),       do: :gt
    def group_compare(_, builtin(:non_neg_integer)),       do: :lt
    def group_compare(builtin(:pos_integer), _),           do: :gt
    def group_compare(_, builtin(:pos_integer)),           do: :lt
    def group_compare(_, i) when is_integer(i) and i >= 0, do: :lt
    def group_compare(_, _..b) when b >= 0,                do: :lt

    # group compare for the atom block
    def group_compare(builtin(:atom), _),                  do: :gt
    def group_compare(_, builtin(:atom)),                  do: :lt
    def group_compare(builtin(:module), _),                do: :gt
    def group_compare(_, builtin(:module)),                do: :lt
    def group_compare(builtin(:node), _),                  do: :gt
    def group_compare(_, builtin(:node)),                  do: :lt

    # group compare for iolist
    def group_compare(builtin(:iolist), what), do: Type.Iolist.compare_list(what)
    def group_compare(what, builtin(:iolist)), do: Type.Iolist.compare_list_inv(what)

    # group compare for strings
    def group_compare(%Type{module: String, name: :t, params: []}, right) do
      %Type.Bitstring{unit: 8}
      |> Type.compare(right)
      |> case do
        :eq -> :lt
        order -> order
      end
    end
    def group_compare(%Type{module: String, name: :t, params: [p]}, right) do
      lowest_idx = case p do
        i when is_integer(i) -> [i]
        range = _.._ -> range
        %Type.Union{of: ints} -> ints
      end
      |> Enum.min

      %Type.Bitstring{size: lowest_idx * 8}
      |> Type.compare(right)
      |> case do
        :eq -> :lt
        order -> order
      end
    end

    def group_compare(_, _), do: :gt
  end

  subtype do
    def subtype?(builtin(:iolist), list = %Type.List{}) do
      Type.Iolist.supertype_of_iolist?(list)
    end
    def subtype?(%Type{module: String, name: :t, params: p}, right) do
      case p do
        [] -> Type.subtype?(builtin(:binary), right)
        [i] when is_integer(i) ->
          Type.subtype?(%Type.Bitstring{size: i * 8}, right)
        range = _.._ ->
          Enum.all?(range, &Type.subtype?(%Type.Bitstring{size: &1 * 8}, right))
        %Type.Union{of: ints} ->
          Enum.all?(ints, &Type.subtype?(%Type.Bitstring{size: &1 * 8}, right))
      end
    end
    def subtype?(left, right) when is_remote(left) do
      left
      |> Type.fetch_type!
      |> Type.subtype?(right)
    end
    def subtype?(a = builtin(_), b), do: usable_as(a, b, []) == :ok
  end
end

defimpl Inspect, for: Type do
  import Inspect.Algebra

  # special case String.t.  This hides our under-the-hood
  # implementation of sized string types.
  def inspect(%{module: String, name: :t, params: [_]}, _opts) do
    "String.t()"
  end
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
