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

  defguard is_remote(type) when is_struct(type) and
    :erlang.map_get(:__struct__, type) == Type and
    :erlang.map_get(:module, type) != nil

  defguard is_builtin(type) when is_struct(type) and
    :erlang.map_get(:__struct__, type) == Type and
    :erlang.map_get(:module, type) == nil

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
  - group 0: none and foreign calls
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
    - node
    - module
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

  alias Type.Spec

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
      {{^fun, ^arity}, [spec]} ->
        Spec.parse(spec, %{"$mfa": {module, fun, arity}})
      _ -> false
    end)
  end

  def fetch_type!(type = %Type{module: module, name: name, params: params})
      when is_remote(type) do
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
    of_list(rest, Type.Union.of(Type.of(head), so_far))
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

  @spec isa?(t, term) :: boolean
  def isa?(type, term) do
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

    # remote types
    def intersection(type = %Type{module: module, name: name, params: params}, right)
        when is_remote(type) do
      # deal with errors later.
      # TODO: implement type caching system
      left = Type.fetch_type!(module, name, params)
      Type.intersection(left, right)
    end
  end

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

    def group_compare(_, _),                               do: :gt
  end

  subtype do
    def subtype?(builtin(:iolist), list = %Type.List{}) do
      Type.Iolist.supertype_of_iolist?(list)
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
