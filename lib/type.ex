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

  @type coerces :: :type_ok | :type_maybe | :type_error

  @doc """
  collect coercion results.  Currently, uses basic ternary logic.
  """
  def collect(results) do
    Enum.max_by(results, fn
      :type_ok    -> 0
      :type_maybe -> 1
      :type_error -> 2
    end)
  end

  defmacro builtin(type) do
    quote do %Type{module: nil, name: unquote(type)} end
  end

  defdelegate of(literal, context), to: Type.Typeable

  @spec coercion({t, t}) :: coerces
  def coercion({subject, target}), do: coercion(subject, target)

  @spec coercion(t, t) :: coerces
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

  import Type, only: :macros

  def coercion(_, builtin(:any)),  do: :type_ok
  def coercion(_, builtin(:none)), do: :type_error

  @integer_subtypes ~w(neg_integer non_neg_integer pos_integer)a
  # integer rules
  def coercion(builtin(:integer), builtin(int_type))
    when int_type in @integer_subtypes, do: :type_maybe
  def coercion(builtin(:integer), integer) when is_integer(integer), do: :type_maybe
  def coercion(builtin(:integer), _.._), do: :type_maybe

  def coercion(builtin(int_type), builtin(:integer))
    when int_type in @integer_subtypes, do: :type_ok

  def coercion(builtin(:neg_integer), builtin(:non_neg_integer)), do: :type_error
  def coercion(builtin(:neg_integer), builtin(:pos_integer)), do: :type_error
  def coercion(builtin(:neg_integer), integer) when is_integer(integer) and integer < 0, do: :type_ok
  def coercion(builtin(:neg_integer), a.._) when a < 0, do: :type_maybe

  def coercion(builtin(:non_neg_integer), builtin(:neg_integer)), do: :type_error
  def coercion(builtin(:non_neg_integer), builtin(:pos_integer)), do: :type_maybe
  def coercion(builtin(:non_neg_integer), integer) when is_integer(integer) and integer >= 0, do: :type_ok
  def coercion(builtin(:non_neg_integer), _..a) when a >= 0, do: :type_maybe

  def coercion(builtin(:pos_integer), builtin(:non_neg_integer)), do: :type_ok
  def coercion(builtin(:pos_integer), builtin(:neg_integer)), do: :type_error
  def coercion(builtin(:pos_integer), integer) when is_integer(integer) and integer > 0, do: :type_ok
  def coercion(builtin(:pos_integer), _..a) when a > 0, do: :type_maybe

  # atoms
  @atom_subtypes ~w(module node)a
  def coercion(builtin(:atom), builtin(atom_type))
    when atom_type in @atom_subtypes, do: :type_maybe

  def coercion(builtin(type), builtin(type)), do: :type_ok
  def coercion(builtin(:any), _), do: :type_maybe
  def coercion(_, _), do: :type_error
end
