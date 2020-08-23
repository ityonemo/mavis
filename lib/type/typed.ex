defprotocol Type.Typed do
  def coercion(subject, target)
end

defimpl Type.Typed, for: Integer do
  import Type, only: :macros

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
  import Type, only: :macros

  def coercion(_, builtin(:any)), do: :type_ok

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
  import Type, only: :macros

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

  def coercion(_, _), do: :type_error
end

# remember, the empty list is its own type
defimpl Type.Typed, for: List do
  import Type, only: :macros

  def coercion([], builtin(:any)), do: :type_ok
  def coercion([], builtin(:iolist)), do: :type_ok
  def coercion([], []), do: :type_ok
  def coercion([], %Type.List{nonempty: false}), do: :type_ok
  def coercion([], _), do: :type_error
end
