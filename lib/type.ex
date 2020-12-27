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
  iex> Type.intersection(pos_integer(), -10..10)
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
  iex> Type.type_match?(node_type(), :foo)
  false
  iex> Type.type_match?(node_type(), :nonode@nohost)
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

  @typedoc """
  output type for `c:Type.Inference.Api.infer/1` and `c:Type.Inference.Api.infer/3`
  """
  @type inferred :: Type.Function.t | Type.Union.t(Type.Function.t)

  @primitive_builtins ~w(none neg_integer pos_integer float node_type module
  atom reference port pid iolist any)a

  @doc false
  def primitive_builtins, do: @primitive_builtins

  @composite_builtins ~w(term integer non_neg_integer tuple arity byte
  map binary bitstring boolean char charlist nonempty_charlist fun
  function identifier iodata keyword list nonempty_list
  maybe_improper_list nonempty_maybe_improper_list mfa no_return number
  struct timeout)a

  @doc false
  def composite_builtins, do: @composite_builtins

  @builtins @primitive_builtins ++ @composite_builtins
  @doc false
  def builtins, do: @builtins

  import Type.Helpers, only: [defbuiltin: 1, defbuiltin: 3]

  # primitive builtins
  defbuiltin :none
  defbuiltin :neg_integer
  defbuiltin :pos_integer
  defbuiltin :float
  defbuiltin :node_type,
             %Type{module: nil, name: :node, params: []},
             "%Type{name: :node}"
  defbuiltin :module
  defbuiltin :atom
  defbuiltin :pid
  defbuiltin :port
  defbuiltin :reference
  defbuiltin :iolist
  defbuiltin :any

  # composite builtins ("basic")
  defbuiltin :non_neg_integer,
             %Type.Union{of: [pos_integer(), 0]},
             "%Type.Union{of: [pos_integer(), 0]}"
  defbuiltin :integer,
             %Type.Union{of: [pos_integer(), 0, neg_integer()]},
             "%Type.Union{of: [pos_integer(), 0, neg_integer()]}"
  defbuiltin :map,
             %Type.Map{optional: %{any() => any()}},
             "%Type.Map{optional: %{any() => any()}}"
  defbuiltin :tuple,
             %Type.Tuple{elements: [], fixed: false},
             "%Type.Tuple{elements: [], fixed: false}"
  # composite builtins (built-in types)
  defbuiltin :no_return, none(), "%Type{name: :none}"
  defbuiltin :arity, 0..255, "0..255"
  defbuiltin :byte, 0..255, "0..255"
  defbuiltin :char, 0..0x10_FFFF, "0..0x10_FFFF"
  defbuiltin :number,
             %Type.Union{of: [float(), pos_integer(), 0, neg_integer()]},
             "%Type.Union{of: [float(), pos_integer(), 0, neg_integer()]}"
  defbuiltin :timeout,
             %Type.Union{of: [:infinity, pos_integer(), 0]},
             "%Type.Union{of: [:infinity, pos_integer(), 0]}"
  defbuiltin :boolean,
             %Type.Union{of: [true, false]},
             "%Type.Union{of: [true, false]}"
  defbuiltin :identifier,
             %Type.Union{of: [pid(), port(), reference()]},
             "%Type.Union{of: [pid(), port(), reference()]}"
  defbuiltin :fun,
             %Type.Function{params: :any, return: any()},
             "%Type.Function{params: :any, return: any()}"
  defbuiltin :function,
             %Type.Function{params: :any, return: any()},
             "%Type.Function{params: :any, return: any()}"
  defbuiltin :mfa,
             %Type.Tuple{elements: [module(), atom(), arity()]},
             "%Type.Tuple{elements: [module(), atom(), arity()]}"
  defbuiltin :struct,
             %Type.Map{required: %{__struct__: atom()}, optional: %{atom() => any()}},
             "%Type.Map{required: %{__struct__: atom()}, optional: %{atom() => any()}}"
  defbuiltin :nonempty_charlist,
             %Type.List{type: 0..0x10_FFFF, final: [], nonempty: true},
             "%Type.List{type: 0..0x10_FFFF, nonempty: true}"
  defbuiltin :nonempty_list,
             %Type.List{type: any(), final: [], nonempty: true},
             "%Type.List{type: any(), nonempty: true}"
  defbuiltin :nonempty_maybe_improper_list,
             %Type.List{type: any(), final: any(), nonempty: true},
             "%Type.List{type: any(), final: any(), nonempty: true}"
  defbuiltin :charlist,
             %Type.List{type: 0..0x10_FFFF, final: [], nonempty: false},
             "%Type.List{type: 0..0x10_FFFF}"
  defbuiltin :keyword,
             %Type.List{
               type: %Type.Tuple{elements: [atom(), any()]},
               final: [],
               nonempty: false},
             "%Type.List{type: tuple({atom(), any()})}"
  defbuiltin :list,
             %Type.List{type: any(), final: [], nonempty: false},
             "%Type.List{type: any()}"
  defbuiltin :maybe_improper_list,
             %Type.List{type: any(), final: any(), nonempty: false},
             "%Type.List{type: any(), final: any()}"
  defbuiltin :binary,
             %Type.Bitstring{size: 0, unit: 8},
             "%Type.Bitstring{unit: 8}"
  defbuiltin :iodata,
             %Type.Union{of: [binary(), iolist()]},
             "%Type.Union{of: [binary(), iolist()]}"
  defbuiltin :bitstring,
             %Type.Bitstring{size: 0, unit: 1},
             "%Type.Bitstring{unit: 1}"
  defbuiltin :term, any(), "%Type{name: :any}"

  @doc """
  use this for when you must use a runtime value to obtain a builtin type struct

  not usable in guards
  """
  defmacro builtin(type_ast) do
    cases = [{:->, [], [[:node], {:node_type, [], []}]}
      | Enum.map(@builtins, &{:->, [], [[&1], {&1, [], []}]})]
    {:case, [], [type_ast, [do: cases]]}
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
  @doc type: true
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

  defp struct_of(module, kv) do
    {:%, [], [
      {:__aliases__, [alias: false], [module]},
      {:%{}, [], kv}
    ]}
  end

  @doc """
  generates a list of a particular type.  A last parameter of `...`
  indicates that the list should be nonempty

  ### Examples:

  ```elixir
  iex> import Type, only: :macros
  iex> list(...)
  %Type.List{type: %Type{name: :any}, nonempty: true}
  iex> list(1..10)
  %Type.List{type: 1..10}
  iex> list(1..10, ...)
  %Type.List{type: 1..10, nonempty: true}
  ```

  if it's passed a keyword list, it is interpreted as a keyword list.

  ```elixir
  iex> import Type, only: :macros
  iex> list(foo: pos_integer())
  %Type.List{type: %Type.Tuple{elements: [:foo, %Type{name: :pos_integer}]}}
  ```

  * usable in guards *
  """
  @doc type: true
  defmacro list({:..., _, _}) do
    Macro.escape(%Type.List{type: any(), nonempty: true})
  end
  defmacro list([{k, v}]) when is_atom(k) do
    quote do
      %Type.List{type: unquote(struct_of(:"Type.Tuple", elements: [k, v]))}
    end
  end
  defmacro list(lst) when is_list(lst) do
    tuples = lst
    |> Enum.sort_by(fn {k, _} when is_atom(k) -> k end, :desc)
    |> Enum.map(fn {k, v} -> struct_of(:"Type.Tuple", elements: [k, v]) end)

    quote do
      %Type.List{type: unquote(struct_of(:"Type.Union", of: tuples))}
    end
  end
  defmacro list(ast) do
    quote do %Type.List{type: unquote(ast)} end
  end
  defmacro list(ast, {:..., _, _}) do
    quote do %Type.List{type: unquote(ast), nonempty: true} end
  end

  @doc """
  generates the tuple type from a tuple ast.  If the tuple contains
  `...` it will generate the generic any tuple.

  See `Type.Tuple` for an explanation of deviations from dialyzer in the
  implementation of this type.

  ```elixir
  iex> import Type, only: :macros
  iex> tuple {...}
  %Type.Tuple{elements: [], fixed: false}
  iex> tuple {:ok, pos_integer()}
  %Type.Tuple{elements: [:ok, %Type{name: :pos_integer}]}
  iex> tuple {:error, atom(), pos_integer()}
  %Type.Tuple{elements: [:error, %Type{name: :atom}, %Type{name: :pos_integer}]}
  ```

  * usable in guards *
  """
  @doc type: true
  defmacro tuple({a, {:..., _, any}}) when is_atom(any) do
    struct_of(:"Type.Tuple", elements: a, fixed: false)
  end
  defmacro tuple({a, b}) do
    struct_of(:"Type.Tuple", elements: [a, b])
  end
  defmacro tuple({:{}, _, what}) do
    {elements, fixed} = find_elements(what)
    struct_of(:"Type.Tuple", elements: elements, fixed: fixed)
  end

  def find_elements(elements, so_far \\ [])
  def find_elements([{:..., _, _}], so_far), do: {Enum.reverse(so_far), false}
  def find_elements([], so_far), do: {Enum.reverse(so_far), true}
  def find_elements([a | rest], so_far), do: find_elements(rest, [a | so_far])

  @doc """
  generates the map type from a map ast.  Unspecified keys default to
  required if singletons, and optional if non-singletons.

  ```elixir
  iex> import Type, only: :macros
  iex> map %{foo: pos_integer()}
  %Type.Map{required: %{foo: %Type{name: :pos_integer}}}
  iex> map %{required(1) => atom()}
  %Type.Map{required: %{1 => %Type{name: :atom}}}
  iex> map %{optional(:bar) => atom()}
  %Type.Map{optional: %{bar: %Type{name: :atom}}}
  ```

  """
  @doc type: true
  defmacro map({:%{}, _, map_ast}) do
    map_list = map_ast
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
    |> Enum.map(&(&1))
    |> Enum.map(fn {k, v} -> {k, {:%{}, [], v}} end)

    struct_of(:"Type.Map", map_list)
  end

  @doc """
  generates the function type from a type-like ast.  Note that the AST
  must be in a parentheses set.  If the parameters are `...`, it will
  generate the any function; for the generic n-arity function use `_`
  for each of the parameters.

  ### Examples:

  ```elixir
  iex> import Type, only: :macros
  iex> function (atom() -> pos_integer())
  %Type.Function{params: [%Type{name: :atom}], return: %Type{name: :pos_integer}}
  iex> function (... -> pos_integer())
  %Type.Function{params: :any, return: %Type{name: :pos_integer}}
  iex> function (_, _ -> pos_integer())
  %Type.Function{params: 2, return: %Type{name: :pos_integer}}
  ```

  If you want to tag function variables or constrain them, you can
  pass a keyword or atom list to the second parameter.  These variables
  must appear in the return.

  ```elixir
  iex> import Type, only: :macros
  iex> function (i -> i when i: var)
  %Type.Function{params: [%Type.Function.Var{name: :i}],
                return: %Type.Function.Var{name: :i}}
  iex> function (i -> i when i: pos_integer())
  %Type.Function{params: [%Type.Function.Var{name: :i, constraint: %Type{name: :pos_integer}}],
                 return: %Type.Function.Var{name: :i, constraint: %Type{name: :pos_integer}}}
  ```

  *usable in guards*
  """
  @doc type: true
  defmacro function([{:->, _, [[{:..., _, _}], return]}]) do
    quote do %Type.Function{params: :any, return: unquote(return)} end
  end
  # special case zero-arity
  defmacro function([{:->, _, [[], return]}]) do
    quote do %Type.Function{params: [], return: unquote(return)} end
  end
  defmacro function([{:->, _, [params, {:when, _, [return, constraints]}]}]) do
    # TODO: fail if any constraint is not in the param or in the return.
    c_f = constraints_to_lambda(constraints)
    parsed_params = c_f.(params, c_f)
    parsed_return = c_f.(return, c_f)
    quote do
      %Type.Function{params: unquote(parsed_params), return: unquote(parsed_return)}
    end
  end
  defmacro function([{:->, _, [params, return]}]) do
    # TODO: fail if there's a partial underscore match
    if Enum.all?(params, &match?({:_, _, _}, &1)) do
      quote do %Type.Function{params: unquote(length(params)), return: unquote(return)} end
    else
      quote do %Type.Function{params: unquote(params), return: unquote(return)} end
    end
  end

  # generates a y-combinator that aggressively converts ASTs which are single
  # variables into var variables.
  defp constraints_to_lambda(constraints) do
    cmap = constraints
    |> Enum.map(fn
      {id, {:var, _, _}} -> {id, quote do any() end}
      any -> any
    end)
    |> Enum.into(%{})

    fn
      {id, meta, atom}, _ when is_atom(atom) and is_map_key(cmap, id) ->
        {:%, meta,
        [
          {:__aliases__, [alias: false], [:"Type.Function.Var"]},
          {:%{}, meta, [name: id, constraint: cmap[id]]}
        ]}
      {id, meta, list}, f when is_list(list) ->
        {id, meta, f.(list, f)}
      list, f when is_list(list) ->
        Enum.map(list, &(f.(&1, f)))
      any, _ -> any
    end
  end

  @doc """
  generates type literals.

  - For bitstrings and lists, this is wrapped in the `Type.Literal`
  struct.
  - For singletons (empty list, integers, atoms), this is a no-op.
  - For other composite values, this gets decomposed to
  singleton values (possibly including literals themselves.)
  - note that pids, ports, and references will not work.

  ### Examples:

  ```elixir
  iex> import Type, only: :macros
  iex> literal("foo")
  %Type.Literal{value: "foo"}
  iex> literal(47.0)
  %Type.Literal{value: 47.0}
  iex> literal([:foo, :bar])
  %Type.Literal{value: [:foo, :bar]}
  iex> literal(%{foo: :bar})
  %Type.Map{required: %{foo: :bar}}
  iex> literal([])
  []
  iex> literal(47)
  47
  iex> literal(:foo)
  :foo
  iex> literal({:ok, "bar"})
  %Type.Tuple{elements: [:ok, %Type.Literal{value: "bar"}]}
  iex> literal({:ok, "bar", 1})
  %Type.Tuple{elements: [:ok, %Type.Literal{value: "bar"}, 1]}
  iex> literal(%{"foo" => "bar"})
  %Type.Map{required: %{%Type.Literal{value: "foo"} => %Type.Literal{value: "bar"}}
  ```

  *usable in guards*
  """
  defmacro literal(value), do: do_literal(value)

  defp do_literal(value) when is_atom(value) or is_integer(value) or value == [] do
    value
  end
  defp do_literal(value) when
    is_bitstring(value) or is_float(value) or is_list(value) do
    Macro.escape(%Type.Literal{value: value})
  end
  defp do_literal({:%{}, meta, kv}) do
    requireds = Enum.map(kv, fn {k, v} -> {do_literal(k), do_literal(v)} end)
    quote do
      %Type.Map{required: unquote({:%{}, meta, requireds})}
    end
  end
  defp do_literal({a, b}) do
    e0 = do_literal(a)
    e1 = do_literal(b)
    quote do
      %Type.Tuple{elements: [unquote(e0), unquote(e1)]}
    end
  end
  defp do_literal({:{}, _meta, elements}) do
    e = Enum.map(elements, &do_literal/1)
    quote do
      %Type.Tuple{elements: unquote(e)}
    end
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

  @doc """
  guard that tests if the selected type is a singleton type.  This is
  a type that has only one value associated with it.

  ### Example:
  ```
  iex> Type.is_singleton(:foo)
  true
  iex> Type.is_singleton(%Type{name: :any})
  false
  ```
  """
  @doc guard: true
  defguard is_singleton(type) when is_atom(type) or is_integer(type) or type == []

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
  iex> Type.subtype?(remote(String.t()), binary)
  true
  iex> Type.subtype?(binary, remote(String.t()))
  false
  ```
  """
  defdelegate subtype?(type, target), to: Type.Properties

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

  @spec intersection(t, t) :: t
  @doc """
  outputs the type which is guaranteed to satisfy the following conditions:

  - if a term is in both types, it is in the result type.
  - if a term is not in either type, it is not in the result type.

  ### Example:
  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersection(non_neg_integer(), -10..10)
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
  iex> import Type, only: :macros
  iex> Type.intersection([pos_integer(), -1..10, -6..6])
  1..6
  ```
  """
  def intersection([]), do: none()
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
  iex> Type.compare(integer(), pid())
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
  "map(%{foo: :bar})"
  iex> inspect Type.of(%{1 => :one})
  "map(%{1 => :one})"
  iex> inspect Type.of(%{"foo" => :bar, "baz" => "quux"})
  "map(%{optional(String.t()) => :bar | String.t()})"
  iex> inspect Type.of(1..10)
  "map(%Range{first: 1, last: 10})"
  ```
  """
  def of(value)
  def of(integer) when is_integer(integer), do: integer
  def of(float) when is_float(float), do: float()
  def of(atom) when is_atom(atom), do: atom
  def of(reference) when is_reference(reference), do: reference()
  def of(port) when is_port(port), do: port()
  def of(pid) when is_pid(pid), do: pid()
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
  def of(bitstring) when is_bitstring(bitstring) do
    of_bitstring(bitstring)
  end

  defp of_list([head | rest], so_far) do
    of_list(rest, Type.union(Type.of(head), so_far))
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
    Enum.map(type_list, &Type.intersection(type, &1))
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

  defdelegate normalize(type), to: Type.Properties
end

defimpl Type.Properties, for: Type do
  # LUT for builtin types groups.
  @groups_for %{
    none: 0, neg_integer: 1, non_neg_integer: 1, pos_integer: 1,
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
    def usable_as(neg_integer(), a, meta) when is_integer(a) and a < 0 do
      {:maybe, [Message.make(neg_integer(), a, meta)]}
    end
    def usable_as(neg_integer(), a..b, meta) when a < 0 do
      {:maybe, [Message.make(neg_integer(), a..b, meta)]}
    end

    # positive integer
    def usable_as(pos_integer(), a, meta) when is_integer(a) and a > 0 do
      {:maybe, [Message.make(pos_integer(), a, meta)]}
    end
    def usable_as(pos_integer(), a..b, meta) when b > 0 do
      {:maybe, [Message.make(pos_integer(), a..b, meta)]}
    end

    # atom
    def usable_as(node_type(), atom(), _meta), do: :ok
    def usable_as(node_type(), atom, meta) when is_atom(atom) do
      if valid_node?(atom) do
        {:maybe, [Message.make(node_type(), atom, meta)]}
      else
        {:error, Message.make(node_type(), atom, meta)}
      end
    end
    def usable_as(module(), atom(), _meta), do: :ok
    def usable_as(module(), atom, meta) when is_atom(atom) do
      # TODO: consider elaborating on this and making more specific
      # warning messages for when the module is or is not detected.
      {:maybe, [Message.make(module(), atom, meta)]}
    end
    def usable_as(atom(), node_type(), meta) do
      {:maybe, [Message.make(atom(), node_type(), meta)]}
    end
    def usable_as(atom(), module(), meta) do
      {:maybe, [Message.make(atom(), module(), meta)]}
    end
    def usable_as(atom(), atom, meta) when is_atom(atom) do
      {:maybe, [Message.make(atom(), atom, meta)]}
    end

    # iolist
    def usable_as(iolist(), [], meta) do
      {:maybe, [Message.make(iolist(), [], meta)]}
    end
    def usable_as(iolist(), list = %Type.List{}, meta) do
      Type.Iolist.usable_as_list(list, meta)
    end

    # any
    def usable_as(any(), any_other_type, meta) do
      {:maybe, [Message.make(any(), any_other_type, meta)]}
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
    Type.usable_as(binary(), target, meta)
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
    def intersection(neg_integer(), a) when is_integer(a) and a < 0, do: a
    def intersection(neg_integer(), a..b) when b < 0, do: a..b
    def intersection(neg_integer(), -1.._), do: -1
    def intersection(neg_integer(), a.._) when a < 0, do: a..-1
    # positive integer
    def intersection(pos_integer(), a) when is_integer(a) and a > 0, do: a
    def intersection(pos_integer(), a..b) when a > 0, do: a..b
    def intersection(pos_integer(), _..1), do: 1
    def intersection(pos_integer(), _..b) when b > 0, do: 1..b
    # atoms
    def intersection(node_type(), atom) when is_atom(atom) do
      if valid_node?(atom), do: atom, else: none()
    end
    def intersection(node_type(), atom()), do: node_type()
    def intersection(module(), atom) when is_atom(atom) do
      if valid_module?(atom), do: atom, else: none()
    end
    def intersection(module(), atom()), do: module()
    def intersection(atom(), module()), do: module()
    def intersection(atom(), node_type()), do: node_type()
    def intersection(atom(), atom) when is_atom(atom), do: atom
    # iolist
    def intersection(iolist(), any), do: Type.Iolist.intersection_with(any)

    # strings
    def intersection(remote(String.t), target = %Type{module: String, name: :t}), do: target
    def intersection(target = %Type{module: String, name: :t}, remote(String.t)), do: target
    def intersection(%Type{module: String, name: :t, params: [lp]},
                     %Type{module: String, name: :t, params: [rp]}) do
      case Type.intersection(lp, rp) do
        none() -> none()
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
        [] -> none()
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
    def group_compare(pos_integer(), _),           do: :gt
    def group_compare(_, pos_integer()),           do: :lt
    def group_compare(_, i) when is_integer(i) and i >= 0, do: :lt
    def group_compare(_, _..b) when b >= 0,                do: :lt

    # group compare for the atom block
    def group_compare(atom(), _),                  do: :gt
    def group_compare(_, atom()),                  do: :lt
    def group_compare(module(), _),                do: :gt
    def group_compare(_, module()),                do: :lt
    def group_compare(node_type(), _),                  do: :gt
    def group_compare(_, node_type()),                  do: :lt

    # group compare for iolist
    def group_compare(iolist(), what), do: Type.Iolist.compare_list(what)
    def group_compare(what, iolist()), do: Type.Iolist.compare_list_inv(what)

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
    def subtype?(iolist(), list = %Type.List{}) do
      Type.Iolist.supertype_of_iolist?(list)
    end
    def subtype?(%Type{module: String, name: :t, params: p}, right) do
      case p do
        [] -> Type.subtype?(binary(), right)
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
    def subtype?(a, b) when is_primitive(a), do: usable_as(a, b, []) == :ok
  end

  # downconverts an arity/1 String.t(_) type to String.t()
  def normalize(type = %Type{module: String, name: :t, params: [_]}) do
    %{type | params: []}
  end
  def normalize(type), do: type
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
