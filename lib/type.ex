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

  defdelegate usable_as(type, target, meta \\ []), to: Type.Typed
  defdelegate subtype?(type, target), to: Type.Typed

  defguard is_neg_integer(n) when is_integer(n) and n < 0
  defguard is_pos_integer(n) when is_integer(n) and n > 0

  @spec order({t, t}) :: boolean
  def order({t1, t2}), do: order(t1, t2)

  @spec order(t, t) :: boolean
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
  defdelegate order(a, b), to: Type.Typed

  @type group :: 0..13

  @doc """
  the typegroup of the type;
  NB: group assignments may change.
  """
  @spec typegroup(t) :: group
  defdelegate typegroup(type), to: Type.Typed

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

        # preload a group_order definition here.
        def group_order(any, any), do: true
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
    none: 0, neg_integer: 1, non_neg_integer: 1, pos_integer: 1, integer: 1,
    float: 2, atom: 3, reference: 4, group: 5, port: 6, pid: 7, any: 12}

  def typegroup(%{module: nil, name: name, params: []}) do
    @groups_for[name]
  end

  def order(this, other) do
    this_group = Type.typegroup(this)
    other_group = Type.typegroup(other)
    cond do
      this_group > other_group -> true
      this_group < other_group -> false
      true -> group_order(this, other)
    end
  end

  import Type, only: [builtin: 1]

  # group order for the integer block.
  def group_order(type, type),                   do: true
  def group_order(builtin(:integer), _),         do: true
  def group_order(_, builtin(:integer)),         do: false
  def group_order(builtin(:non_neg_integer), _), do: true
  def group_order(_, builtin(:non_neg_integer)), do: false
  def group_order(builtin(:pos_integer), _),     do: true
  def group_order(_, builtin(:pos_integer)),     do: false
  def group_order(builtin(:neg_integer), _),     do: true
  def group_order(_, builtin(:neg_integer)),     do: false

  def group_order(builtin(:atom), _), do: true
  def group_order(_, builtin(:atom)), do: false

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

  def make(type, target, meta) do
    %__MODULE__{type: type, target: target, meta: meta}
  end
end
