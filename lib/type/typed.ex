defprotocol Type.Typed do
  @spec usable_as(Type.t, Type.t, keyword) :: Type.ternary
  def usable_as(subject, target, meta)

  @spec subtype?(Type.t, Type.t) :: boolean
  def subtype?(subject, target)

  @spec order(Type.t, Type.t) :: boolean
  def order(a, b)

  @spec typegroup(Type.t) :: Type.group
  def typegroup(type)
end

defimpl Type.Typed, for: Integer do
  import Type, only: [builtin: 1, is_pos_integer: 1, is_neg_integer: 1]

  use Type.Impl

  @spec group_order(integer, Type.t) :: boolean
  def group_order(_, builtin(:integer)),               do: true
  def group_order(left, builtin(:neg_integer)),        do: left >= 0
  def group_order(_, builtin(:non_neg_integer)),       do: false
  def group_order(_, builtin(:pos_integer)),           do: false
  def group_order(left, _..last),                      do: left > last
  def group_order(left, right) when is_integer(right), do: left >= right
  def group_order(left, %Type.Union{of: ints}) do
    group_order(left, List.last(ints))
  end

  def usable_as(i, i, _),                                     do: :ok
  def usable_as(i, a..b, _) when a <= i and i <= b,           do: :ok
  def usable_as(i, builtin(:pos_integer), _) when i > 0,      do: :ok
  def usable_as(i, builtin(:neg_integer), _) when i < 0,      do: :ok
  def usable_as(i, builtin(:non_neg_integer), _) when i >= 0, do: :ok
  def usable_as(_, builtin(:integer), _),                     do: :ok
  def usable_as(_, builtin(:any), _),                         do: :ok
  def usable_as(type, target, meta) do
    {:error, Type.Message.make(type, target, meta)}
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end

defimpl Type.Typed, for: Range do
  import Type, only: [builtin: 1]

  use Type.Impl

  def group_order(_, builtin(:integer)),                  do: false
  def group_order(_, builtin(:pos_integer)),              do: false
  def group_order(_, builtin(:non_neg_integer)),          do: false
  def group_order(_..last, builtin(:neg_integer)),        do: last >= 0
  def group_order(first1..last, first2..last),            do: first1 < first2
  def group_order(_..last1, _..last2),                    do: last1 > last2
  def group_order(_..last, right) when is_integer(right), do: last >= right
  def group_order(first..last, %Type.Union{of: [init | types]}) do
    case List.last(types) do
      _..b when b < last -> true
      _..b ->
        # the range is bigger if it's bigger than the biggest union
        Type.order(init, first) && (last >= b)
      i when i < last -> true
      i when is_integer(i) ->
        Type.order(init, first) && (last >= i)
      _ -> false
    end
  end

  def usable_as(range, range, _),                                do: :ok
  def usable_as(_, builtin(:any), _),                            do: :ok
  def usable_as(_, builtin(:integer), _),                        do: :ok
  def usable_as(a.._, builtin(:pos_integer), _) when a > 0,      do: :ok
  def usable_as(a.._, builtin(:non_neg_integer), _) when a >= 0, do: :ok
  def usable_as(_..a, builtin(:neg_integer), _) when a < 0,      do: :ok

  def usable_as(a..b, builtin(:pos_integer), meta) when b > 0 do
    {:maybe, [Type.Message.make(a..b, builtin(:pos_integer), meta)]}
  end
  def usable_as(a..b, builtin(:neg_integer), meta) when a < 0 do
    {:maybe, [Type.Message.make(a..b, builtin(:neg_integer), meta)]}
  end
  def usable_as(a..b, builtin(:non_neg_integer), meta) when b >= 0 do
    {:maybe, [Type.Message.make(a..b, builtin(:non_neg_integer), meta)]}
  end
  def usable_as(a..b, target, meta)
      when is_integer(target) and a <= target and target <= b do
    {:maybe, [Type.Message.make(a..b, target, meta)]}
  end
  def usable_as(a..b, c..d, meta) do
    cond do
      a >= c and b <= d -> :ok
      a > d or b < c-> {:error, Type.Message.make(a..b, c..d, meta)}
      true ->
        {:maybe, [Type.Message.make(a..b, c..d, meta)]}
    end
  end
  def usable_as(type, target, meta) do
    {:error, Type.Message.make(type, target, meta)}
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end

defimpl Type.Typed, for: Atom do
  import Type, only: [builtin: 1]

  use Type.Impl

  def group_order(_, builtin(:atom)), do: false
  def group_order(left, right), do: left >= right

  def usable_as(atom, atom,        _), do: :ok
  def usable_as(_, builtin(:atom), _), do: :ok
  def usable_as(_, builtin(:any),  _), do: :ok
  def usable_as(atom, type, meta) do
    {:error, Type.Message.make(atom, type, meta)}
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end

# remember, the empty list is its own type
defimpl Type.Typed, for: List do
  import Type, only: [builtin: 1]

  use Type.Impl

  def group_order([], %Type.List{nonempty: ne}), do: ne

  def usable_as([], [], _), do: :ok
  def usable_as([], builtin(:any), _), do: :ok
  def usable_as([], t = %Type.List{nonempty: false, final: f}, meta) do
    if subtype?([], f) do
      :ok
    else
      {:error, Type.Message.make([], t, meta)}
    end
  end
  def usable_as([], t, meta), do: {:error, Type.Message.make([], t, meta)}

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end
