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
    quote do %Type{module: nil, name: unquote(type)} end
  end

  defdelegate usable_as(type, target, meta \\ []), to: Type.Properties
  defdelegate subtype?(type, target), to: Type.Properties

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
  defdelegate order(a, b), to: Type.Properties

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


  defmacro usable_as_start do
    quote do
      def usable_as(type, type, meta), do: :ok
      def usable_as(type, Type.builtin(:any), meta), do: :ok
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

  defmodule Impl do
    # exists to prevent mistakes when generating functions.
    # TODO: move to parent module.
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

defimpl Type.Properties, for: Type do
  # LUT for builtin types groups.
  @groups_for %{
    none: 0, neg_integer: 1, non_neg_integer: 1, pos_integer: 1, integer: 1,
    float: 2, atom: 3, reference: 4, port: 6, pid: 7, any: 12}

  import Type, only: :macros

  alias Type.Message

  def usable_as(type, type, _meta), do: :ok

  # none type
  def usable_as(builtin(:none), target, meta) do
    {:error, Message.make(builtin(:none), target, meta)}
  end

  # trap anys as ok
  def usable_as(_, builtin(:any), _meta), do: :ok

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

  # any
  def usable_as(builtin(:any), any_other_type, meta) do
    {:maybe, [Message.make(builtin(:any), any_other_type, meta)]}
  end

  usable_as_coda()

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

  def subtype?(a, %Type.Union{of: types}) do
    Enum.any?(types, &Type.subtype?(a, &1))
  end
  def subtype?(a = builtin(_), b), do: usable_as(a, b, []) == :ok
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
