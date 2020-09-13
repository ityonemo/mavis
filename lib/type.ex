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

  @type warnings :: {:warn, [Type.Message.t]}
  @type error  :: {:error, Type.Message.t}
  @type status :: :ok | warnings | error

  defmacro builtin(type) do
    quote do %Type{module: nil, name: unquote(type)} end
  end

  defdelegate usable_as(type, target), to: Type.Typed
  defdelegate subtype?(type, target), to: Type.Typed

  defguard is_neg_integer(n) when is_integer(n) and n < 0
  defguard is_pos_integer(n) when is_integer(n) and n > 0

  @spec order(t, t) :: boolean
  @doc """
  Types have an order that facilitates calculation of collapsing values into
  unions.

  For literals this follows the order in the erlang type system.  For type
  classes and special literals (like ranges) the type should be placed in
  order just in front of its lowest element.

  Types are organized into groups, which exist as a fastlane for comparing
  order between two different types (see `typegroup/1`)

  The order is as follows:
  - group 0: any
  - group 1
    - integer
    - neg_integer
    - [negative integer literal]
    - non_neg_integer
    - 0
    - pos_integer
    - [positive integer literal]
  - group 2: float
  - group 3
    - atom
    - [atom literal]
  - group 4: reference
  - group 5
    - `params: :any` functions (ordered by `retval`, then `params` in dictionary order)
    - `params: list` functions (ordered by `retval`, then `params` in dictionary order)
  - group 6: port
  - group 7: pid
  - group 8
    - any tuple
    - defined arity tuple
  - group 9: maps
  - group 10:
    - `nonempty: false` lists
    - iodata
    - `nonempty: true` lists
  - group 11: bitstrings
  - group 12: none

  ranges (group 1) come before the lowest integer in the range.
  a union comes before the first represented item in its union.
  """
  defdelegate order(a, b), to: Type.Typed

  @type group :: 0..13

  @doc """
  the typegroup of the type;
  NB: group assignments may change.
  """
  @spec typegroup(t) :: group
  defdelegate typegroup(type), to: Type.Typed

  #def order(a, a),                                       do: true
  #def order(builtin(:any), _any),                        do: false
  #def order(_any, builtin(:any)),                        do: true
  #def order(builtin(:integer), _any),                    do: false
  #def order(_any, builtin(:integer)),                    do: true,
  #def order(builtin(:neg_integer), _any),                do: false
  #def order(_any, builtin(:neg_integer)),                do: true
  #def order(m, n) when is_neg_integer(m) and is_neg_integer(n), do: m >= n
  #def order(m.._, n) when is_neg_integer(m) and is_integer(n), do: m >= n
  #def order(m.._, n.._),                                 do: m >= n
  #def order(n, _any) when is_neg_integer(n),             do: false
  #def order(_any, n) when is_neg_integer(n),             do: true
  #def order(m.._, _any) when is_neg_integer(m),          do: false
  #def order(_any, m.._) when is_neg_integer(m),          do: true
  #def order(builtin(:non_neg_integer), _any),            do: false
  #def order(_any, builtin(:non_neg_integer)),            do: true
  #def order(0.._, _any),                                 do: false
  #def order(_any, 0.._),                                 do: true
  #def order(0, _any),                                    do: false
  #def order(_any, 0),                                    do: true
  #def order(builtin(:pos_integer), _any),                do: false
  #def order(_any, builtin(:pos_integer)),                do: true
  #def order(m, n) when is_integer(m) and is_integer(n),  do: m >= n
  #def order(integer, _any) when is_pos_integer(integer), do: false
  #def order(_any, integer) when is_pos_integer(integer), do: true
  #def order(_.._, _any),                                 do: false
  #def order(_any, _.._),                                 do: true
  #def order(builtin(:atom), _any),                       do: false
  #def order(_any, builtin(:atom)),                       do: true
  #def order(atom, _any) when is_atom(atom),              do: false
  #def order(_any, atom) when is_atom(atom),              do: true
  #def order(%Tuple{elements: :any}, _any),               do: false
  #def order(_any, %Tuple{elements: :any}),               do: true
  #def order(%Tuple{elements: e1}, %Tuple{elements: e2})
  #    when length(e1) == length(e2)                      do
  #  e1
  #  |> Enum.zip(e2)
  #  |> Enum.all?(&order/1)
  #end
  #def order(%Tuple{elements: e1}, %Tuple{elements: e2}), do: length(e1) > length(e2)
  #def order(%Tuple{}, _any),                             do: false
  #def order(_any, %Tuple{}),                             do: true
  #def order(l1 = %List{}, l2 = %List{}),                 do: order_lists(l1, l2)
  #def order(%List{}, _any),                              do: false
  #def order(_any, %List{}),                              do: true
  #def order(f1 = %Function{}, f2 = %Function{}),         do: order_functions(f1, f2)
  #def order(%Function{}, _any),                          do: false
  #def order(_any, %Function{}),                          do: true
#
  #def order(a, b),                                       do: a >= b
#
  ## private shim for ordering eveything else.
  #defp order({e1, e2}), do: order(e1, e2)
#
  #defp order_lists(%{nonempty: false}, %{nonempty: true}), do: false
  #defp order_lists(%{nonempty: true}, %{nonempty: false}), do: true
  #defp order_lists(l1, l2) do
  #  if l1.type == l2.type do
  #    order(l1.final, l2.final)
  #  else
  #    order(l1.type, l2.type)
  #  end
  #end
#
  #defp order_functions(f1 = %{params: :any}, f2 = %{params: :any}) do
  #  order(f1.return, f2.return)
  #end
  #defp order_functions(%{params: :any}, %{params: _list}), do: false
  #defp order_functions(%{params: _list}, %{params: :any}), do: true
  #defp order_functions(f1, f2) do
  #  [f1.return | f1.params]
  #  |> Enum.zip([f2.return | f2.params])
  #  |> Enum.all?(&order/1)
  #end
#
  #defdelegate of(literal, context), to: Type.Typeable
#
  #def coercion({subject, target}), do: coercion(subject, target)

  defmodule Impl do
    # exists to prevent mistakes when generating functions
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

    @callback group_order(Type.t, Type.t) :: boolean

    defmacro __using__(_) do
      group = __CALLER__.module
      |> Module.split
      |> List.last
      |> :erlang.map_get(@group_for)

      quote bind_quoted: [group: group] do
        @behaviour Type.Impl

        @group group
        def typegroup(_), do: @group

        def order(this, other) do
          other_group = Type.typegroup(other)
          cond do
            other_group < @group -> true
            other_group > @group -> false
            true -> group_order(this, other)
          end
        end
      end
    end
  end

  defdelegate coercion(subject, target), to: Type.Typed

  defimpl String.Chars do
    def to_string(%{module: nil, name: atom, params: params}) do
      param_list = Enum.join(params, ", ")
      "#{atom}(#{param_list})"
    end
    def to_string(%{module: module, name: name, params: params}) do
      param_list = Enum.join(params, ", ")
      "#{inspect module}.#{name}(#{param_list})"
    end
  end
end

defimpl Type.Typed, for: Type do
  # LUT for builtin types groups.
  @groups_for %{
    any: 0, integer: 1, neg_integer: 1, non_neg_integer: 1,
    pos_integer: 1, float: 2, atom: 3, reference: 4, group: 5,
    port: 6, pid: 7, none: 12}

  def typegroup(%{module: nil, name: name, params: []}) do
    @groups_for[name]
  end

  def order(this, other) do
    other_group = Type.typegroup(other)
    cond do
      other_group < @group -> true
      other_group > @group -> false
      true -> group_order(this, other)
    end
  end

  import Type, only: [builtin: 1]

  def group_order(builtin(:non_neg_integer), integer) when is_integer(integer) do
    0 >= integer
  end

  #def coercion(_, builtin(:any)),  do: :type_ok
  #def coercion(_, builtin(:none)), do: :type_error
#
  #@integer_subtypes ~w(neg_integer non_neg_integer pos_integer)a
  ## integer rules
  #def coercion(builtin(:integer), builtin(int_type))
  #  when int_type in @integer_subtypes, do: :type_maybe
  #def coercion(builtin(:integer), integer) when is_integer(integer), do: :type_maybe
  #def coercion(builtin(:integer), _.._), do: :type_maybe
#
  #def coercion(builtin(int_type), builtin(:integer))
  #  when int_type in @integer_subtypes, do: :type_ok
#
  #def coercion(builtin(:neg_integer), builtin(:non_neg_integer)), do: :type_error
  #def coercion(builtin(:neg_integer), builtin(:pos_integer)), do: :type_error
  #def coercion(builtin(:neg_integer), integer) when is_integer(integer) and integer < 0, do: :type_ok
  #def coercion(builtin(:neg_integer), a.._) when a < 0, do: :type_maybe
#
  #def coercion(builtin(:non_neg_integer), builtin(:neg_integer)), do: :type_error
  #def coercion(builtin(:non_neg_integer), builtin(:pos_integer)), do: :type_maybe
  #def coercion(builtin(:non_neg_integer), integer) when is_integer(integer) and integer >= 0, do: :type_ok
  #def coercion(builtin(:non_neg_integer), _..a) when a >= 0, do: :type_maybe
#
  #def coercion(builtin(:pos_integer), builtin(:non_neg_integer)), do: :type_ok
  #def coercion(builtin(:pos_integer), builtin(:neg_integer)), do: :type_error
  #def coercion(builtin(:pos_integer), integer) when is_integer(integer) and integer > 0, do: :type_ok
  #def coercion(builtin(:pos_integer), _..a) when a > 0, do: :type_maybe
#
  ## atoms
  #@atom_subtypes ~w(module node)a
  #def coercion(builtin(:atom), atom) when is_atom(atom), do: :type_maybe
  #def coercion(builtin(:atom), builtin(atom_type))
  #  when atom_type in @atom_subtypes, do: :type_maybe
#
  #def coercion(builtin(type), builtin(type)), do: :type_ok
  #def coercion(builtin(:any), _), do: :type_maybe
  #def coercion(_, _), do: :type_error
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
end
