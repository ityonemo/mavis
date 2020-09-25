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
  import Type, only: :macros

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

  usable_as do
    def usable_as(i, a..b, _) when a <= i and i <= b,           do: :ok
    def usable_as(i, builtin(:pos_integer), _) when i > 0,      do: :ok
    def usable_as(i, builtin(:neg_integer), _) when i < 0,      do: :ok
    def usable_as(i, builtin(:non_neg_integer), _) when i >= 0, do: :ok
    def usable_as(_, builtin(:integer), _),                     do: :ok
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end

defimpl Type.Typed, for: Range do
  import Type, only: :macros

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

  usable_as do
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
    # strange stitched ranges
    def usable_as(a..b, union = %Type.Union{}, meta) when a <= -1 and b >= 0 do
      pos_leftovers = if b == 0,  do: 0,  else: 0..b
      neg_leftovers = if a == -1, do: -1, else: a..-1

      if leftover_check(union, :neg_integer, pos_leftovers) or
         leftover_check(union, :non_neg_integer, neg_leftovers) do
        :ok
      else
        usable_as_union_fallback(a..b, union, meta)
      end
    end
  end

  defp leftover_check(union = %{of: types}, int_class, leftover) do
    (builtin(int_class) in types) and Type.subtype?(leftover, union)
  end

  defp usable_as_union_fallback(challenge, target, meta) do
    target.of
    |> Enum.map(&Type.usable_as(challenge, &1, meta))
    |> Enum.reduce(&Type.ternary_or/2)
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end

defimpl Type.Typed, for: Atom do
  import Type, only: :macros

  use Type.Impl

  def group_order(_, builtin(:atom)), do: false
  def group_order(left, right), do: left >= right

  usable_as do
    def usable_as(_, builtin(:atom), _), do: :ok
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end

# remember, the empty list is its own type
defimpl Type.Typed, for: List do
  import Type, only: :macros

  use Type.Impl

  def group_order([], %Type.List{nonempty: ne}), do: ne

  usable_as do
    def usable_as([], %Type.List{nonempty: false, final: []}, _meta), do: :ok
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end
