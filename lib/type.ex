defmodule Type do

  @enforce_keys [:name]
  defstruct @enforce_keys ++ [:module, params: []]

  @type t :: %__MODULE__{
    name: atom,
    module: nil | module,
    params: [t]
  } | integer | Range.t | atom
  | Type.AsBoolean.t
  | Type.List.t | []
  | Type.Bitstring.t
  | Type.Tuple.t
  | Type.Map.t
  | Type.Function.t
  | Type.Union.t

  @type maybe :: {:maybe, [Type.Message.t]}
  @type error  :: {:error, Type.Message.t}
  @type ternary :: :ok | maybe | error

  defmacro builtin(type) do
    quote do %Type{module: nil, name: unquote(type), params: []} end
  end

  # note, you can't use remote in matches.
  defmacro remote({{:., _, [module_ast, name]}, _, params}) do
    module = Macro.expand(module_ast, __CALLER__)
    Macro.escape(%Type{module: module, name: name, params: params})
  end

  defdelegate usable_as(type, target, meta \\ []), to: Type.Properties
  defdelegate subtype?(type, target), to: Type.Properties

  defguard is_neg_integer(n) when is_integer(n) and n < 0
  defguard is_pos_integer(n) when is_integer(n) and n > 0

  @spec intersection(t, t) :: t
  defdelegate intersection(a, b), to: Type.Properties

  def union(types) when is_list(types) do
    Enum.into(types, struct(Type.Union))
  end

  def intersect([]), do: builtin(:none)
  def intersect([a]), do: a
  def intersect([a | b]) do
    Type.intersection(a, Type.intersect(b))
  end

  @spec compare({t, t}) :: :lt | :gt | :eq
  def compare({t1, t2}), do: compare(t1, t2)

  @spec compare(t, t) :: :lt | :gt | :eq
  @doc """
  Types have an order that facilitates calculation of collapsing values into
  unions.

  For literals this follows the order in the erlang type system.  For type
  classes and special literals (like ranges) the type should be placed in
  order just after of its highest element.

  Types are organized into groups, which exist as a fastlane for comparing
  order between two different types (see `typegroup/1`)

  The order is as follows:
  - group 0: none
  - group 1
    - [negative integer literal]
    - neg_integer
    - [nonnegative integer literal]
    - pos_integer
    - non_neg_integer
    - integer
  - group 2: float
  - group 3
    - [atom literal]
    - atom
  - group 4: reference
  - group 5
    - `params: list` functions (ordered by `retval`, then `params` in dictionary order)
    - `params: :any` functions (ordered by `retval`, then `params` in dictionary order)
  - group 6: port
  - group 7: pid
  - group 8
    - defined arity tuple
    - any tuple
  - group 9: maps
  - group 10:
    - `nonempty: true` list
    - empty list literal
    - `nonempty: false` lists
  - group 11: bitstrings
  - group 12: any

  ranges (group 1) come after the highest integer in the range, bigger
  ranges come after smaller ranges

  iolist (group 10) come in the appropriate place in the range,
  a union comes after the highest represented item in its union,
  """
  defdelegate compare(a, b), to: Type.Properties

  @type group :: 0..12

  @doc """
  the typegroup of the type;
  NB: group assignments may change.
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
  def ternary_and({:maybe, left}, {:maybe, right}), do: {:maybe, left ++ right}
  def ternary_and({:maybe, _}, error),              do: error
  def ternary_and(error, {:maybe, _}),              do: error
  def ternary_and(error, _),                        do: error

  @spec ternary_or(ternary, ternary) :: ternary
  @doc false
  # ternary or which performs comparisons of ok, maybe, and error
  # types and composes them into the appropriate ternary logic result.
  def ternary_or(:ok, _),                          do: :ok
  def ternary_or(_, :ok),                          do: :ok
  def ternary_or({:maybe, left}, {:maybe, right}), do: {:maybe, left ++ right}
  def ternary_or({:maybe, left}, _),               do: {:maybe, left}
  def ternary_or(_, {:maybe, right}),              do: {:maybe, right}
  def ternary_or(error, _),                        do: error

  ## fetching AnD StuFF

  def fetch_spec(module, fun, arity) do
    with {:module, _} <- Code.ensure_loaded(module),
         {:ok, specs} <- Code.Typespec.fetch_specs(module),
         spec when spec != nil <- find_spec(module, specs, fun, arity) do
      {:ok, spec}
    else
      :error ->
        {:error, "this module was not found"}
      nil ->
        if function_exported?(module, fun, arity) do
          :unknown
        else
          {:error, "this function was not found"}
        end
      error -> error
    end
  end

  def find_spec(module, specs, fun, arity) do
    Enum.find_value(specs, fn
      {{^fun, ^arity}, [spec]} -> parse_spec(spec, %{"$module": module})
      _ -> false
    end)
  end

  def fetch_type!(%Type{module: module, name: name, params: params})
      when not is_nil(module) do
    fetch_type!(module, name, params)
  end
  def fetch_type!(module, name, params \\ []) do
    case fetch_type(module, name, params) do
      {:ok, specs} -> specs
      {:error, msg} -> raise "#{inspect msg.type} type not found"
    end
  end

  def fetch_type(module, name, params \\ [], meta \\ []) do
    with {:ok, specs} <- Code.Typespec.fetch_types(module),
         {type, assignments} <- find_type(module, specs, name, params) do
      {:ok, parse_spec(type, assignments)}
    else
      _ -> {:error, struct(Type.Message,
        type: %Type{module: module, name: name, params: params},
        meta: meta ++ [message: "not found"])}
    end
  end

  @prefixes ~w(type typep opaque)a

  defp find_type(module, specs, name, params) do
    Enum.find_value(specs, fn
      {t, {^name, type, tparams}}
          when t in @prefixes and length(tparams) == length(params) ->
        assignments = tparams
        |> Enum.map(fn {:var, _, key} -> key end)
        |> Enum.zip(params)
        |> Enum.into(%{"$module": module})
        {type, assignments}
      _ ->
        false
    end)
  end

  # TODO:
  # move to own module
  def parse_spec(spec, assigns \\ %{})
  def parse_spec({:type, _, :map, :any}, _assigns) do
    struct(Type.Map, optional: builtin(:any))
  end
  def parse_spec({:type, _, :map, params}, assigns) when is_list(params) do
    Enum.reduce(params, struct(Type.Map), fn
      {:type, _, :map_field_assoc, [src_type, dst_type]}, map = %{optional: optional} ->
        %{map | optional: Map.put(optional, parse_spec(src_type, assigns), parse_spec(dst_type, assigns))}
      {:type, _, :map_field_exact, [src_type, dst_type]}, map = %{required: required} ->
        %{map | required: Map.put(required, parse_spec(src_type, assigns), parse_spec(dst_type, assigns))}
    end)
  end

  # fix assigns
  def parse_spec({:var, _, name}, assigns) when is_map_key(assigns, name) do
    assigns[name]
  end
  def parse_spec({:var, _, :_}, _assigns) do
    builtin(:any)
  end
  def parse_spec({:var, _, name}, assigns) when is_map_key(assigns, {name, :subtype_of}) do
    struct(Type.Function.Var, name: name, constraint: assigns[{name, :subtype_of}])
  end
  def parse_spec({:var, _, name}, _assigns) do
    struct(Type.Function.Var, name: name)
  end
  # general types
  def parse_spec({:type, _, :range, [first, last]}, assigns), do: parse_spec(first, assigns)..parse_spec(last, assigns)
  def parse_spec({:op, _, :-, value}, assigns), do: -parse_spec(value, assigns)
  def parse_spec({:integer, _, value}, _), do: value
  def parse_spec({:atom, _, value}, _), do: value
  def parse_spec({:type, _, :fun, [{:type, _, :any}, return]}, assigns) do
    struct(Type.Function, params: :any, return: parse_spec(return, assigns))
  end
  def parse_spec({:type, _, :fun, [{:type, _, :product, params}, return]}, assigns) do
    param_types = Enum.map(params, &parse_spec(&1, assigns))
    struct(Type.Function, params: param_types, return: parse_spec(return, assigns))
  end
  def parse_spec({:type, _, :tuple, :any}, _) do
    struct(Type.Tuple, elements: :any)
  end
  def parse_spec({:type, _, :tuple, elements}, assigns) do
    struct(Type.Tuple, elements: Enum.map(elements, &parse_spec(&1, assigns)))
  end
  # empty list
  def parse_spec({:type, _, nil, []}, _), do: []
  # overrides
  def parse_spec({:type, _, :no_return, []}, _), do: builtin(:none)
  def parse_spec({:type, _, :term, []}, _), do: builtin(:any)
  def parse_spec({:type, _, :arity, []}, _), do: 0..255
  def parse_spec({:type, _, :byte, []}, _), do: 0..255
  def parse_spec({:type, _, :char, []}, _), do: 0..0x10FFFF
  def parse_spec({:type, _, :number, []}, _) do
    Type.Union.of(builtin(:integer), builtin(:float))
  end
  def parse_spec({:type, _, :timeout, []}, _) do
    Type.Union.of(builtin(:non_neg_integer), :infinity)
  end
  def parse_spec({:type, _, :identifier, []}, _) do
    ~w(port pid reference)a
    |> Enum.map(&builtin/1)
    |> Enum.into(struct(Type.Union))
  end
  def parse_spec({:type, _, :boolean, []}, _) do
    Type.Union.of(true, false)
  end
  def parse_spec({:type, _, :fun, []}, _) do
    struct(Type.Function, params: :any, return: builtin(:any))
  end
  def parse_spec({:type, _, :function, []}, _) do
    struct(Type.Function, params: :any, return: builtin(:any))
  end
  def parse_spec({:type, _, :mfa, []}, _) do
    struct(Type.Tuple, elements: [builtin(:module), builtin(:atom), 0..255])
  end
  def parse_spec({:type, _, :list, []}, _) do
    struct(Type.List, type: builtin(:any))
  end
  def parse_spec({:type, _, :list, [type]}, assigns) do
    struct(Type.List, type: parse_spec(type, assigns))
  end
  def parse_spec({:type, _, :nonempty_list, []}, _) do
    struct(Type.List, type: builtin(:any), nonempty: true)
  end
  def parse_spec({:type, _, :nonempty_list, [type]}, assigns) do
    struct(Type.List, type: parse_spec(type, assigns), nonempty: true)
  end

  def parse_spec({:type, _, :maybe_improper_list, []}, _) do
    struct(Type.List, final: builtin(:any))
  end
  def parse_spec({:type, _, :maybe_improper_list, [type, final]}, assigns) do
    struct(Type.List,
      type: parse_spec(type, assigns),
      final: Type.Union.of(parse_spec(final, assigns), []))
  end
  def parse_spec({:type, _, :nonempty_improper_list, [type, final]}, assigns) do
    struct(Type.List,
      type: parse_spec(type, assigns),
      nonempty: true,
      final: parse_spec(final, assigns))
  end
  def parse_spec({:type, _, :nonempty_maybe_improper_list, []}, _) do
    struct(Type.List, nonempty: true, final: builtin(:any))
  end
  def parse_spec({:type, _, :nonempty_maybe_improper_list, [type, final]}, assigns) do
    struct(Type.List,
      type: parse_spec(type, assigns),
      nonempty: true,
      final: Type.Union.of(parse_spec(final, assigns), []))
  end
  def parse_spec({:type, _, :bitstring, []}, _) do
    struct(Type.Bitstring, size: 0, unit: 1)
  end
  def parse_spec({:type, _, :binary, []}, _) do
    struct(Type.Bitstring, size: 0, unit: 8)
  end
  def parse_spec({:type, _, :binary, [size, unit]}, assigns) do
    struct(Type.Bitstring, size: parse_spec(size, assigns), unit: parse_spec(unit, assigns))
  end
  def parse_spec({:type, _, :iodata, []}, _) do
    Type.Union.of(struct(Type.Bitstring, size: 0, unit: 8), builtin(:iolist))
  end
  def parse_spec({:type, _, :union, types}, assigns) do
    types
    |> Enum.map(&parse_spec(&1, assigns))
    |> Enum.into(struct(Type.Union))
  end
  # overridden remote types
  def parse_spec({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :charlist}, []]}, _) do
    struct(Type.List, type: 0..0x10FFFF)
  end
  def parse_spec({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :nonempty_charlist}, []]}, _) do
    struct(Type.List, type: 0..0x10FFFF, nonempty: true)
  end
  def parse_spec({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, []]}, _) do
    struct(Type.List, type: struct(Type.Tuple, elements: [builtin(:atom), builtin(:any)]))
  end
  def parse_spec({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, [type]]}, assigns) do
    struct(Type.List, type: struct(Type.Tuple, elements: [builtin(:atom), parse_spec(type, assigns)]))
  end
  # general remote type
  def parse_spec({:remote_type, _, [module, name, args]}, assigns) do
    %Type{module: parse_spec(module, assigns),
          name: parse_spec(name, assigns),
          params: Enum.map(args, &parse_spec(&1, assigns))}
  end
  # general local type
  def parse_spec({:user_type, _, name, args}, assigns) do
    %Type{module: Map.fetch!(assigns, :"$module"),
          name: name,
          params: Enum.map(args, &parse_spec(&1, assigns))}
  end
  # annotated types can just be ignored
  def parse_spec({:ann_type, _, [_type_annotation, type]}, assigns) do
    parse_spec(type, assigns)
  end
  # default builtin
  def parse_spec({:type, _, type, []}, _), do: builtin(type)
  def parse_spec({:type, _, :bounded_fun, [fun, constraints]}, assigns) do
    # TODO: write a test against constraint assignment
    parse_spec(fun, add_constraints(assigns, constraints))
  end

  defp add_constraints(assigns, []), do: assigns
  defp add_constraints(assigns, [constraint | rest]) do
    assigns
    |> add_constraint(constraint)
    |> add_constraints(rest)
  end

  defp add_constraint(assigns, {:type, _, :constraint,
                                [{:atom, _, :is_subtype},
                                [{:var, _, name}, type]]}) do
    Map.put(assigns, {name, :subtype_of}, parse_spec(type, assigns))
  end

  defmacro usable_as_start do
    quote do
      def usable_as(type, type, meta), do: :ok
      def usable_as(type, Type.builtin(:any), meta), do: :ok

      if __MODULE__ == Type.Properties.Type.Bitstring do
        import Type, only: [remote: 1]
        def usable_as(%Type.Bitstring{size: 0, unit: 0}, remote(String.t()), _), do: :ok
      end

      def usable_as(challenge, target = %Type{module: m}, meta) when not is_nil(m) do
        case Type.usable_as(challenge, Type.fetch_type!(target)) do
          :ok ->
            msg = """
            #{inspect target} is usable as base type #{inspect challenge}
            but #{inspect target} is considered to be a strict subtype because
            it is a remote encapsulation.
            """
            {:maybe, [Type.Message.make(challenge, target, [message: msg])]}
          maybe_or_error -> maybe_or_error
        end
      end
    end
  end

  @doc """
  coda for "usable_as" function guard lists.  Performs the following two things:

  - catches usable_as against unions; and performs the appropriate attempt to
    match into each of the union's subtypes.
  - catches all other attempts to run usable_as, and returns `:error, metadata}`

  """
  defmacro usable_as_coda do
    quote do
      def usable_as(challenge, %Type.Union{of: types}, meta) do
        types
        |> Enum.map(&Type.usable_as(challenge, &1, meta))
        |> Enum.reduce(&Type.ternary_or/2)
      end

      def usable_as(challenge, union, meta) do
        {:error, Type.Message.make(challenge, union, meta)}
      end
    end
  end

  @doc """
  Wraps the "usable_as" function headers in common "top" and "fallback" headers.
  This prevents errors from being made in code that must be common to all types.

  Top function matches:
  - matches equal types and makes them output :ok
  - matches usable_as with `builtin(:any)` and makes them output :ok

  Fallback function matches:
  - see `usable_as_coda/0`

  """
  defmacro usable_as(do: block) do
    quote do
      Type.usable_as_start()

      unquote(block)

      Type.usable_as_coda()
    end
  end

  defmacro intersection(do: block) do
    quote do
      @spec intersection(Type.t, Type.t) :: Type.t
      def intersection(type, type), do: type
      def intersection(type, builtin(:any)), do: type

      if __MODULE__ == Type.Properties.Type do
      def intersection(builtin(:any), type) do
        type
      end
      end

      def intersection(left, right = %Type{module: m}) when not is_nil(m) do
        # special case.
        Type.intersection(left, Type.fetch_type!(right))
      end

      unless __MODULE__ == Type.Properties.Type.Union do
      def intersection(type, union = %Type.Union{}) do
        Type.intersection(union, type)
      end
      end

      unquote(block)

      def intersection(_, _), do: builtin(:none)
    end
  end

  defmacro group_compare(do: block) do
    quote do
      def group_compare(type, type), do: :eq

      # check for dual remote types
      def group_compare(left = %Type{module: m1}, right = %Type{module: m2})
          when not (is_nil(m1) or is_nil(m2)) do
        case group_compare(Type.fetch_type!(left), Type.fetch_type!(right)) do
          :eq ->
            Type.lexical_compare(left, right)
          order -> order
        end
      end

      def group_compare(left = %Type{module: m}, right)
          when not is_nil(m) do
        left
        |> Type.fetch_type!
        |> group_compare(right)
        |> case do
          :eq -> :lt
          order -> order
        end
      end

      def group_compare(left, right = %Type{module: m})
          when not is_nil(m) do
        left
        |> group_compare(Type.fetch_type!(right))
        |> case do
          :eq -> :gt
          order -> order
        end
      end

      def group_compare(type1, %Type.Union{of: [type2 | _]}) do
        case group_compare(type1, type2) do
          :gt -> :gt
          _ -> :lt
        end
      end

      unquote(block)
    end
  end

  defmacro subtype(do: block) do
    quote do
      def subtype?(a, a), do: true

      unless __MODULE__ == Type.Properties.Type.Union do
        def subtype?(a, %Type.Union{of: types}) do
          Enum.any?(types, &Type.subtype?(a, &1))
        end
      end

      if __MODULE__ == Type.Properties.Type do
        def subtype?(builtin(:none), _), do: false
      end

      def subtype?(_, builtin(:any)), do: true

      # TODO make is_remote and is_builtin guards
      def subtype?(left, right = %Type{module: m}) when not is_nil(m) do
        r_solved = Type.fetch_type!(right)
        if left == r_solved do
          false
        else
          Type.subtype?(left, r_solved)
        end
      end

      unquote(block)
    end
  end
  defmacro subtype(:usable_as) do
    quote do
      def subtype?(a, b), do: usable_as(a, b, []) == :ok
    end
  end

  def lexical_compare(left = %{module: m, name: n}, right) do
    with {:m, ^m} <- {:m, right.module},
         {:n, ^n} <- {:n, right.name} do
      left.params
      |> Enum.zip(right.params)
      |> Enum.each(fn {l, r} ->
        comp = Type.compare(l, r)
        unless comp == :eq do
          throw comp
        end
      end)
      raise "unreachable"
    else
      {:m, _} -> if m > right.module, do: :gt, else: :lt
      {:n, _} -> if n > right.name, do: :gt, else: :lt
    end
  catch
    :gt -> :gt
    :lt -> :lt
  end

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
  def of(function) when is_function(function) do
    case Type.Function.infer(function) do
      {:ok, type} -> type
    end
  end
  def of(bitstring) when is_bitstring(bitstring) do
    of_bitstring(bitstring, 0)
  end

  defp of_list([head | rest], so_far) do
    of_list(rest, Type.Union.of(head, so_far))
  end
  defp of_list([], so_far) do
    %Type.List{type: so_far, nonempty: true}
  end
  defp of_list(non_list, so_far) do
    %Type.List{type: so_far, nonempty: true, final: Type.of(non_list)}
  end

  def of_bitstring(bitstring, bits_so_far \\ 0)
  def of_bitstring(<<>>, 0), do: %Type.Bitstring{size: 0, unit: 0}
  def of_bitstring(<<>>, _size), do: remote(String.t)
  def of_bitstring(<<0::1, chr::7, rest :: binary>>, so_far) when chr != 0 do
    of_bitstring(rest, so_far + 8)
  end
  def of_bitstring(<<6::3, _::5, 2::2, _::6, rest :: binary>>, so_far) do
    of_bitstring(rest, so_far + 16)
  end
  def of_bitstring(<<14::4, _::4, 2::2, _::6, 2::2, _::6, rest::binary>>, so_far) do
    of_bitstring(rest, so_far + 24)
  end
  def of_bitstring(<<30::5, _::3, 2::2, _::6, 2::2, _::6, 2::2, _::6, rest::binary>>, so_far) do
    of_bitstring(rest, so_far + 32)
  end
  def of_bitstring(bitstring, so_far) do
    %Type.Bitstring{size: bit_size(bitstring) + so_far, unit: 0}
  end

  #######################################################################
  ## `use Type` section - boilerplate for preventing mistakes

  @group_for %{
    "Integer" => 1,
    "Range" => 1,
    "Atom" => 3,
    "Function" => 5,
    "Tuple" => 8,
    "Map" => 9,
    "List" => 10,
    "Bitstring" => 11
  }

  @callback group_compare(Type.t, Type.t) :: :lt | :gt | :eq

  # exists to prevent mistakes when generating functions.
  defmacro __using__(_) do
    group = __CALLER__.module
    |> Module.split
    |> List.last
    |> :erlang.map_get(@group_for)

    quote bind_quoted: [group: group] do
      @behaviour Type

      @group group
      def typegroup(_), do: @group

      def compare(this, other) do
        other_group = Type.typegroup(other)
        cond do
          @group > other_group -> :gt
          @group < other_group -> :lt
          true ->
            group_compare(this, other)
        end
      end
    end
  end
end

defimpl Type.Properties, for: Type do
  # LUT for builtin types groups.
  @groups_for %{
    none: 0, neg_integer: 1, non_neg_integer: 1, pos_integer: 1, integer: 1,
    float: 2, atom: 3, reference: 4, port: 6, pid: 7, iolist: 10, any: 12}

  import Type, only: :macros

  alias Type.Message

  def usable_as(type, type, _meta), do: :ok

  # none type
  def usable_as(builtin(:none), target, meta) do
    {:error, Message.make(builtin(:none), target, meta)}
  end

  # trap anys as ok
  def usable_as(_, builtin(:any), _meta), do: :ok

  def usable_as(challenge = %Type{module: m}, target, meta) when not is_nil(m) do
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

  usable_as_coda()

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
    def intersection(builtin(:atom), atom) when is_atom(atom), do: atom
    # iolist
    def intersection(builtin(:iolist), any), do: Type.Iolist.intersection_with(any)

    # remote types
    def intersection(%Type{module: module, name: name, params: params}, right)
        when not is_nil(module) do
      # deal with errors later.
      # TODO: implement type caching system
      left = Type.fetch_type!(module, name, params)
      Type.intersection(left, right)
    end
  end

  def typegroup(%{module: nil, name: name}) do
    @groups_for[name]
  end
  def typegroup(type) do
    type
    |> Type.fetch_type!()
    |> Type.typegroup()
  end

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

    # group compare for iolist
    def group_compare(builtin(:iolist), what), do: Type.Iolist.compare_list(what)
    def group_compare(what, builtin(:iolist)), do: Type.Iolist.compare_list_inv(what)

    def group_compare(_, _),                               do: :gt
  end

  subtype do
    def subtype?(builtin(:iolist), list = %Type.List{}) do
      Type.Iolist.supertype_of_iolist?(list)
    end
    def subtype?(left = %Type{module: m}, right) when not is_nil(m) do
      left
      |> Type.fetch_type!
      |> Type.subtype?(right)
    end
    def subtype?(a = builtin(_), b), do: usable_as(a, b, []) == :ok
  end
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

defmodule Type.Message do
  @enforce_keys [:type, :target]
  defstruct @enforce_keys ++ [meta: []]

  @type t :: %__MODULE__{
    type:   Type.t,
    target: Type.t,
    meta:   [
      file: Path.t,
      line: non_neg_integer,
      warning: atom,
      message: String.t
    ]
  }

  def make(type, target, meta) do
    %__MODULE__{type: type, target: target, meta: meta}
  end
end
