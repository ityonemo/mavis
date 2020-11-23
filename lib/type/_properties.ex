defprotocol Type.Properties do
  @spec usable_as(Type.t, Type.t, keyword) :: Type.ternary
  def usable_as(subject, target, meta)

  @spec subtype?(Type.t, Type.t) :: boolean
  def subtype?(subject, target)

  @spec compare(Type.t, Type.t) :: :gt | :eq | :lt
  def compare(a, b)

  @spec typegroup(Type.t) :: Type.group
  def typegroup(type)

  @spec intersection(Type.t, Type.t) :: Type.t
  def intersection(type, type)

  @spec normalize(Type.t) :: Type.t
  def normalize(type)
end

defimpl Type.Properties, for: Integer do
  import Type, only: :macros

  use Type.Helpers

  group_compare do
    def group_compare(left, neg_integer()),       do: (if left >= 0, do: :gt, else: :lt)
    def group_compare(_, pos_integer()),          do: :lt
    def group_compare(left, _..last),                     do: (if left > last, do: :gt, else: :lt)
    def group_compare(left, right) when is_integer(right) do
      cond do
        left > right -> :gt
        left < right -> :lt
        true -> :eq
      end
    end
    def group_compare(left, %Type.Union{of: ints}) do
      group_compare(left, List.last(ints))
    end
  end

  usable_as do
    def usable_as(i, a..b, _) when a <= i and i <= b,           do: :ok
    def usable_as(i, pos_integer(), _) when i > 0,      do: :ok
    def usable_as(i, neg_integer(), _) when i < 0,      do: :ok
  end

  intersection do
    def intersection(i, a..b) when a <= i and i <= b, do: i
    def intersection(i, neg_integer()) when i < 0, do: i
    def intersection(i, pos_integer()) when i > 0, do: i
  end

  subtype :usable_as
end

defimpl Type.Properties, for: Range do
  import Type, only: :macros

  use Type.Helpers

  group_compare do
    def group_compare(_, pos_integer()),              do: :lt
    def group_compare(_..last, neg_integer()),        do: (if last >= 0, do: :gt, else: :lt)
    def group_compare(first1..last, first2..last),            do: (if first1 < first2, do: :gt, else: :lt)
    def group_compare(_..last1, _..last2),                    do: (if last1 > last2, do: :gt, else: :lt)
    def group_compare(_..last, right) when is_integer(right), do: (if last >= right, do: :gt, else: :lt)
    def group_compare(first..last, %Type.Union{of: [init | types]}) do
      case List.last(types) do
        _..b when b < last -> :gt
        _..b ->
          # the range is bigger if it's bigger than the biggest union
          raise "foo bar"
          Type.compare(init, first) && (last >= b)
        i when i < last -> :gt
        i when is_integer(i) ->
          Type.compare(init, first) && (last >= i)
        _ -> :lt
      end
    end
  end

  usable_as do
    def usable_as(a.._, pos_integer(), _) when a > 0,      do: :ok
    def usable_as(_..a, neg_integer(), _) when a < 0,      do: :ok
    def usable_as(a..b, pos_integer(), meta) when b > 0 do
      {:maybe, [Type.Message.make(a..b, pos_integer(), meta)]}
    end
    def usable_as(a..b, neg_integer(), meta) when a < 0 do
      {:maybe, [Type.Message.make(a..b, neg_integer(), meta)]}
    end
    def usable_as(a..b, target, meta)
        when is_integer(target) and a <= target and target <= b do
      {:maybe, [Type.Message.make(a..b, target, meta)]}
    end
    def usable_as(a..b, c..d, meta) do
      cond do
        a >= c and b <= d -> :ok
        a > d or b < c -> {:error, Type.Message.make(a..b, c..d, meta)}
        true ->
          {:maybe, [Type.Message.make(a..b, c..d, meta)]}
      end
    end
    # strange stitched ranges
    def usable_as(range, union = %Type.Union{of: list}, meta) do
      # take the intersections and make sure they reassemble to the
      # range.
      list
      |> Enum.map(&Type.intersection(&1, range))
      |> Type.union
      |> case do
        none() -> {:error, Type.Message.make(range, union, meta)}
        ^range -> :ok
        _ -> {:maybe, [Type.Message.make(range, union, meta)]}
      end
    end
  end

  intersection do
    def intersection(a..b, i) when a <= i and i <= b, do: i
    def intersection(a.._, _..a), do: a
    def intersection(_..a, a.._), do: a
    def intersection(a..b, c..d) do
      case {a >= c, a > d, b < c, b <= d} do
        {_,     x, y, _} when x or y -> none()
        {false, _, _, true}  -> c..b
        {true,  _, _, true}  -> a..b
        {true,  _, _, false} -> a..d
        {false, _, _, false} -> c..d
      end
    end
    def intersection(a..b,  neg_integer()) when b < 0, do: a..b
    def intersection(-1.._, neg_integer()), do: -1
    def intersection(a.._,  neg_integer()) when a < 0, do: a..-1
    def intersection(a..b,  pos_integer()) when a > 0, do: a..b
    def intersection(_..1,  pos_integer()), do: 1
    def intersection(_..a,  pos_integer()) when a > 1, do: 1..a
  end

  subtype :usable_as
end

defimpl Type.Properties, for: Atom do
  import Type, only: :macros

  use Type.Helpers

  alias Type.Message

  group_compare do
    def group_compare(_, atom()), do: :lt
    def group_compare(left, right),       do: (if left >= right, do: :gt, else: :lt)
  end

  usable_as do
    def usable_as(_, atom(), _), do: :ok
    def usable_as(atom, node_type(), meta) do
      if Type.Properties.Type.valid_node?(atom) do
        :ok
      else
        {:error, Message.make(atom, node_type(), meta)}
      end
    end
    def usable_as(atom, module(), meta) do
      if Type.Properties.Type.valid_module?(atom) do
        :ok
      else
        {:maybe, [Message.make(atom, module(), meta)]}
      end
    end
  end

  intersection do
    def intersection(atom, atom()), do: atom
    def intersection(atom, node_type()) do
      if Type.Properties.Type.valid_node?(atom), do: atom, else: none()
    end
    def intersection(atom, module()) do
      if Type.Properties.Type.valid_module?(atom), do: atom, else: none()
    end
  end

  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end

# remember, the empty list is its own type
defimpl Type.Properties, for: List do
  import Type, only: :macros

  use Type.Helpers

  group_compare do
    def group_compare([], %Type.List{nonempty: ne}), do: (if ne, do: :gt, else: :lt)
    def group_compare(_, _) do
      raise "any list other than the empty list [] is an invalid type!"
    end
  end

  usable_as do
    def usable_as([], %Type.List{nonempty: false, final: []}, _meta), do: :ok
    def usable_as([], iolist(), _), do: :ok
    def usable_as(list, _, _) when is_list(list) and length(list) > 0 do
      raise "any list other than the empty list [] is an invalid type!"
    end
  end

  intersection do
    def intersection([], %Type.List{nonempty: false, final: []}), do: []
    def intersection([], iolist()), do: Type.Iolist.intersection_with([])
    def intersection(list, _) when is_list(list) and length(list) > 0  do
      raise "any list other than the empty list [] is an invalid type!"
    end
  end

  subtype :usable_as
end
