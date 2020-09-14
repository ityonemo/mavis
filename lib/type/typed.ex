defprotocol Type.Typed do
  def coercion(subject, target)

  @spec usable_as(Type.t, Type.t) :: Type.status
  def usable_as(subject, target)

  @spec subtype?(Type.t, Type.t) :: boolean
  def subtype?(subject, target)

  @spec order(Type.t, Type.t) :: boolean
  def order(a, b)

  @spec typegroup(Type.t) :: Type.group
  def typegroup(type)
end

defimpl Type.Typed, for: Integer do
  import Type, only: [builtin: 1]

  use Type.Impl

  @spec group_order(integer, Type.t) :: boolean
  def group_order(_, builtin(:integer)),               do: true
  def group_order(left, builtin(:neg_integer)),        do: left >= 0
  def group_order(_, builtin(:non_neg_integer)),       do: false
  def group_order(_, builtin(:pos_integer)),           do: false
  def group_order(left, _..last),                      do: left > last
  def group_order(left, right) when is_integer(right), do: left >= right

  def coercion(_, builtin(:any)), do: :type_ok

  # integer rules
  def coercion(_, builtin(:integer)), do: :type_ok
  def coercion(i, builtin(:neg_integer)) when i < 0, do: :type_ok
  def coercion(i, builtin(:non_neg_integer)) when i >= 0, do: :type_ok
  def coercion(i, builtin(:pos_integer)) when i > 0, do: :type_ok
  def coercion(i, a..b) when a <= i and i <= b, do: :type_ok

  def coercion(i, i), do: :type_ok
  def coercion(_, _), do: :type_error
end

defimpl Type.Typed, for: Range do
  import Type, only: [builtin: 1]

  use Type.Impl

  def group_order(_, builtin(:integer)),           do: false
  def group_order(_, builtin(:pos_integer)),       do: false
  def group_order(_, builtin(:non_neg_integer)),   do: false
  def group_order(_..last, builtin(:neg_integer)), do: last >= 0
  def group_order(first1..last, first2..last),     do: first1 < first2
  def group_order(_..last1, _..last2),             do: last1 > last2
  def group_order(_..last, right),                 do: last >= right

  def coercion(_, builtin(:any)), do: :typebar

  # integer rules
  def coercion(_, builtin(:integer)), do: :type_ok
  def coercion(_..last,  builtin(:neg_integer))     when last < 0,   do: :type_ok
  def coercion(first.._, builtin(:neg_integer))     when first < 0,  do: :type_maybe
  def coercion(first.._, builtin(:non_neg_integer)) when first >= 0, do: :type_ok
  def coercion(_..last,  builtin(:non_neg_integer)) when last >= 0,  do: :type_maybe
  def coercion(first.._, builtin(:pos_integer))     when first > 0,  do: :type_ok
  def coercion(_..last,  builtin(:pos_integer))     when last > 0,   do: :type_maybe

  def coercion(first..last, integer) when integer >= first and integer <= last, do: :type_maybe
  def coercion(src_a..src_b, tgt_a..tgt_b) do
    case {src_b < tgt_a, src_b <= tgt_b, src_a >= tgt_a, src_a > tgt_b} do
      {true, _,    _,    _   } -> :type_error
      {_,    _,    _,    true} -> :type_error
      {_,    true, true, _   } -> :type_ok
      _ -> :type_maybe
    end
  end

  def coercion(_, _), do: :type_error
end

defimpl Type.Typed, for: Atom do
  import Type, only: [builtin: 1]

  use Type.Impl

  def group_order(_, builtin(:atom)), do: false
  def group_order(left, right), do: left >= right

  def usable_as(_, builtin(:atom)), do: :ok

  def subtype?(_, builtin(:atom)), do: true
  def subtype?(atom, atom),        do: true
  def subtype?(_, _),              do: false

  def coercion(_, builtin(:any)), do: :type_ok

  def coercion(_, builtin(:atom)), do: :type_ok

  def coercion(maybe_module, builtin(:module)) do
    # this is probably buggy.
    if function_exported?(maybe_module, :module_info, 0) do
      :type_ok
    else
      :type_maybe
    end
  end

  def coercion(maybe_node, builtin(:node)) do
    maybe_node
    |> Atom.to_string
    |> String.split("@")
    |> case do
      [_, _] -> :type_ok
      _ -> :type_error
    end
  end
  def coercion(any, any), do: :type_ok

  def coercion(_, _), do: :type_error
end

# remember, the empty list is its own type
defimpl Type.Typed, for: List do
  import Type, only: [builtin: 1]

  use Type.Impl

  def group_order(_, _), do: raise "a child"

  def coercion([], builtin(:any)), do: :type_ok
  def coercion([], builtin(:iolist)), do: :type_ok
  def coercion([], []), do: :type_ok
  def coercion([], %Type.List{nonempty: false}), do: :type_ok
  def coercion([], _), do: :type_error
end
