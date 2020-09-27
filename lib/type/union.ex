defmodule Type.Union do
  defstruct [of: []]
  @type t :: %__MODULE__{of: [Type.t]}

  import Type, only: [builtin: 1]

  @doc """
  special syntax for two-valued union (which is delegated to by the `|` operator)
  """
  def of(left, right) do
    Enum.into([left, right], %__MODULE__{})
  end

  # for now.
  @spec collapse([Type.t]) :: Type.t
  def collapse(types) do
    types
    |> Enum.flat_map(fn
      union = %__MODULE__{} -> union.of
      other_type -> [other_type]
    end)
    |> Enum.sort({:asc, Type})
    |> Enum.uniq
    |> Enum.reduce([], &type_list_merge/2)
    |> case do
      [] -> %Type{name: :none}
      [one] -> one
      list -> %__MODULE__{of: list}
    end
  end

  def type_list_merge(incoming_type, []), do: [incoming_type]
  def type_list_merge(incoming_type, [head | rest]) do
    {result, next} = type_merge(head, incoming_type)
    result ++ type_list_merge(next, rest)
  end

  # integers and ranges
  def type_merge(a, b) when b == a + 1 do
    {[], a..b}
  end
  def type_merge(a..b, c) when c == b + 1 do
    {[], a..c}
  end
  def type_merge(a, b..c) when b == a + 1 do
    {[], a..c}
  end
  def type_merge(a..b, c..d) when c <= b do
    {[], a..d}
  end
  def type_merge(builtin(:neg_integer), _..0) do
    {[builtin(:neg_integer)], 0}
  end
  def type_merge(builtin(:neg_integer), a..b) when a <= 0 and b > 0 do
    {[builtin(:neg_integer)], 0..b}
  end

  # negative integers
  def type_merge(integer, builtin(:neg_integer))
      when is_integer(integer) and integer < 0 do
    {[], builtin(:neg_integer)}
  end
  def type_merge(_..b, builtin(:neg_integer)) when b < 0 do
    {[], builtin(:neg_integer)}
  end

  # positive integers
  def type_merge(integer, builtin(:pos_integer))
      when is_integer(integer) and integer > 0 do
    {[], builtin(:pos_integer)}
  end
  def type_merge(a.._, builtin(:pos_integer)) when a > 0 do
    {[], builtin(:pos_integer)}
  end
  def type_merge(0, builtin(:pos_integer)) do
    {[], builtin(:non_neg_integer)}
  end
  def type_merge(0.._, builtin(:pos_integer)) do
    {[], builtin(:non_neg_integer)}
  end
  def type_merge(-1..b, builtin(:pos_integer)) when b >= 0 do
    {[-1], builtin(:non_neg_integer)}
  end
  def type_merge(a..b, builtin(:pos_integer)) when b >= 0 do
    {[a..-1], builtin(:non_neg_integer)}
  end

  # non-negative integers
  def type_merge(integer, builtin(:non_neg_integer))
      when is_integer(integer) and integer >= 0 do
    {[], builtin(:non_neg_integer)}
  end
  def type_merge(a.._, builtin(:non_neg_integer)) when a >= 0 do
    {[], builtin(:non_neg_integer)}
  end
  def type_merge(-1..b, builtin(:non_neg_integer)) when b >= 0 do
    {[-1], builtin(:non_neg_integer)}
  end
  def type_merge(a..b, builtin(:non_neg_integer)) when b >= 0 do
    {[a..-1], builtin(:non_neg_integer)}
  end
  def type_merge(builtin(:neg_integer), builtin(:non_neg_integer)) do
    {[], builtin(:integer)}
  end

  # integers
  def type_merge(integer, builtin(:integer)) when is_integer(integer) do
    {[], builtin(:integer)}
  end
  def type_merge(a..b, builtin(:integer)) do
    {[], builtin(:integer)}
  end
  def type_merge(builtin(:neg_integer), builtin(:integer)) do
    {[], builtin(:integer)}
  end
  def type_merge(builtin(:pos_integer), builtin(:integer)) do
    {[], builtin(:integer)}
  end
  def type_merge(builtin(:non_neg_integer), builtin(:integer)) do
    {[], builtin(:integer)}
  end

  # atoms
  def type_merge(atom, builtin(:atom)) when is_atom(atom) do
    {[], builtin(:atom)}
  end

  # any
  def type_merge(_, builtin(:any)) do
    {[], builtin(:any)}
  end

  # tuples
  alias Type.Tuple
  def type_merge(%Tuple{}, %Tuple{elements: :any}) do
    {[], %Tuple{elements: :any}}
  end
  def type_merge(lhs = %Tuple{}, rhs = %Tuple{}) do
    merged_elements = lhs.elements
    |> Enum.zip(rhs.elements)
    |> Enum.map(fn
      {type, type} -> type
      {lh, rh} ->
        union = Type.Union.of(lh, rh)
        match?(%Type.Union{}, union) and (union.of == [lh, rh]) and throw :fail
        union
    end)
    {[], %Tuple{elements: merged_elements}}
  catch
    :fail ->
      {[lhs], rhs}
  end

  # any
  def type_merge(_, builtin(:any)) do
    {[], builtin(:any)}
  end

  def type_merge(a, b) do
    {[a], b}
  end

  defimpl Type.Properties do
    import Type, only: [builtin: 1]

    def compare(_union, builtin(:none)), do: :gt
    def compare(union, %Type.Union{}) do
      raise "hell"
    end
    def compare(union, type) do
      union.of
      |> Elixir.List.last
      |> Type.compare(type)
      |> case do
        :eq -> :gt
        order -> order
      end
    end

    def typegroup(union) do
      union.of
      |> Elixir.List.last
      |> Type.Properties.typegroup
    end

    def usable_as(challenge, target, meta) do
      challenge.of
      |> Enum.map(&Type.usable_as(&1, target, meta))
      |> Enum.reduce(fn
        # TO BE REPLACED WITH SOMETHING MORE SOPHISTICATED.
        :ok, :ok                 -> :ok
        :ok, {:maybe, _}         -> {:maybe, nil}
        :ok, {:error, _}         -> {:maybe, nil}
        {:maybe, _}, :ok         -> {:maybe, nil}
        {:error, _}, :ok         -> {:maybe, nil}
        {:maybe, _}, {:maybe, _} -> {:maybe, nil}
        {:maybe, _}, {:error, _} -> {:maybe, nil}
        {:error, _}, {:maybe, _} -> {:maybe, nil}
        {:error, _}, {:error, _} -> {:error, nil}
      end)
      |> case do
        :ok -> :ok
        {:maybe, _} -> {:maybe, [Type.Message.make(challenge, target, meta)]}
        {:error, _} -> {:error, Type.Message.make(challenge, target, meta)}
      end
    end

    def subtype?(%{of: types}, target) do
      Enum.all?(types, &Type.subtype?(&1, target))
    end
  end

  defimpl Collectable do
    alias Type.Union

    def into(original) do
      collector_fun = fn
        # starting with an empty union results in
        list, {:cont, elem} -> [elem | list]
        list, :done -> Union.collapse(list)
        _set, :halt -> :ok
      end

      {original.of, collector_fun}
    end
  end
end
