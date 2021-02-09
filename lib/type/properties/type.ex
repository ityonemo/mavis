
defimpl Type.Properties, for: Type do
  # LUT for builtin types groups.
  @groups_for %{
    none: 0, neg_integer: 1, non_neg_integer: 1, pos_integer: 1,
    float: 2, node: 3, module: 3, atom: 3, reference: 4, port: 6, pid: 7,
    iolist: 10, any: 12}

  import Type, only: :macros

  import Type.Helpers

  alias Type.Message

  usable_as do
    def usable_as(challenge, target = %Type{module: String, name: :t}, meta) do
      usable_as_string(challenge, target, meta)
    end
    def usable_as(challenge = %Type{module: String, name: :t}, target, meta) do
      string_usable_as(challenge, target, meta)
    end

    def usable_as(challenge, target, meta) when is_remote(challenge) do
      challenge
      |> Type.fetch_type!()
      |> Type.usable_as(target, meta)
    end

    # negative integer
    def usable_as(neg_integer(), a, meta) when is_integer(a) and a < 0 do
      {:maybe, [Message.make(neg_integer(), a, meta)]}
    end
    def usable_as(neg_integer(), a..b, meta) when a < 0 do
      {:maybe, [Message.make(neg_integer(), a..b, meta)]}
    end

    # positive integer
    def usable_as(pos_integer(), a, meta) when is_integer(a) and a > 0 do
      {:maybe, [Message.make(pos_integer(), a, meta)]}
    end
    def usable_as(pos_integer(), a..b, meta) when b > 0 do
      {:maybe, [Message.make(pos_integer(), a..b, meta)]}
    end

    # atom
    def usable_as(node_type(), atom(), _meta), do: :ok
    def usable_as(node_type(), atom, meta) when is_atom(atom) do
      if valid_node?(atom) do
        {:maybe, [Message.make(node_type(), atom, meta)]}
      else
        {:error, Message.make(node_type(), atom, meta)}
      end
    end
    def usable_as(module(), atom(), _meta), do: :ok
    def usable_as(module(), atom, meta) when is_atom(atom) do
      # TODO: consider elaborating on this and making more specific
      # warning messages for when the module is or is not detected.
      {:maybe, [Message.make(module(), atom, meta)]}
    end
    def usable_as(atom(), node_type(), meta) do
      {:maybe, [Message.make(atom(), node_type(), meta)]}
    end
    def usable_as(atom(), module(), meta) do
      {:maybe, [Message.make(atom(), module(), meta)]}
    end
    def usable_as(atom(), atom, meta) when is_atom(atom) do
      {:maybe, [Message.make(atom(), atom, meta)]}
    end

    # iolist
    def usable_as(iolist(), type, meta) do
      Type.Iolist.iolist_usable_as(type, meta)
    end

    # any
    def usable_as(any(), any_other_type, meta) do
      {:maybe, [Message.make(any(), any_other_type, meta)]}
    end
  end

  defp usable_as_string(%Type{module: String, name: :t}, %{params: []}, _meta), do: :ok
  defp usable_as_string(challenge = %Type{module: String, name: :t, params: []},
                        target = %{params: [_t]}, meta) do
    {:maybe, [Message.make(challenge, target, meta)]}
  end
  defp usable_as_string(challenge = %Type{module: String, name: :t, params: [pl]},
                        target = %{params: [pr]}, meta) do
    cond do
      Type.subtype?(pl, pr) -> :ok
      Type.subtype?(pr, pl) -> {:maybe, [Message.make(challenge, target, meta)]}
      true -> {:error, Message.make(challenge, target, meta)}
    end
  end
  defp usable_as_string(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end

  defp string_usable_as(%{params: []}, target, meta) do
    Type.usable_as(binary(), target, meta)
  end
  defp string_usable_as(%{params: [size]}, target, meta) when is_integer(size) do
    Type.usable_as(%Type.Bitstring{size: size * 8}, target, meta)
  end
  defp string_usable_as(%{params: [%Type.Union{of: ints}]}, target, meta) do
    ints
    |> Enum.map(&Type.usable_as(%Type.Bitstring{size: &1 * 8}, target, meta))
    |> Enum.reduce(&Type.ternary_and/2)
  end

  intersection do
    # negative integer
    def intersection(neg_integer(), a) when is_integer(a) and a < 0, do: a
    def intersection(neg_integer(), a..b) when b < 0, do: a..b
    def intersection(neg_integer(), -1.._), do: -1
    def intersection(neg_integer(), a.._) when a < 0, do: a..-1
    # positive integer
    def intersection(pos_integer(), a) when is_integer(a) and a > 0, do: a
    def intersection(pos_integer(), a..b) when a > 0, do: a..b
    def intersection(pos_integer(), _..1), do: 1
    def intersection(pos_integer(), _..b) when b > 0, do: 1..b
    # atoms
    def intersection(node_type(), atom) when is_atom(atom) do
      if valid_node?(atom), do: atom, else: none()
    end
    def intersection(node_type(), atom()), do: node_type()
    def intersection(module(), atom) when is_atom(atom) do
      if valid_module?(atom), do: atom, else: none()
    end
    def intersection(module(), atom()), do: module()
    def intersection(atom(), module()), do: module()
    def intersection(atom(), node_type()), do: node_type()
    def intersection(atom(), atom) when is_atom(atom), do: atom
    # other literals
    def intersection(float(), value) when is_float(value), do: value
    # iolist
    def intersection(iolist(), any), do: Type.Iolist.intersection_with(any)

    # strings
    def intersection(remote(String.t), target = %Type{module: String, name: :t}), do: target
    def intersection(specced = %{module: String, name: :t}, remote(String.t)), do: specced
    def intersection(%{module: String, name: :t, params: params}, binary) when is_binary(binary) do
      case params do
        [] -> binary
        [v] when v == :erlang.size(binary) -> binary
        _ -> none()
      end
    end
    def intersection(%Type{module: String, name: :t, params: [lp]},
                     %Type{module: String, name: :t, params: [rp]}) do
      case Type.intersection(lp, rp) do
        none() -> none()
        int_type -> %Type{module: String, name: :t, params: [int_type]}
      end
    end
    def intersection(%{module: String, name: :t, params: [lp]}, bs = %Type.Bitstring{}) do
      lp
      |> case do
        i when is_integer(i) ->
          if sized?(i, bs), do: [i], else: []
        range = _.._ ->
          Enum.filter(range, &sized?(&1, bs))
        %Type.Union{of: ints} ->
          Enum.filter(ints, &sized?(&1, bs))
      end
      |> case do
        [] -> none()
        lst -> %Type{module: String, name: :t, params: [Enum.into(lst, %Type.Union{})]}
      end
    end
    def intersection(%{module: String, name: :t, params: [_]}, _), do: none()

    # remote types
    def intersection(type = %{module: module, name: name, params: params}, right)
        when is_remote(type) do
      # deal with errors later.
      # TODO: implement type caching system
      left = Type.fetch_type!(module, name, params)
      Type.intersection(left, right)
    end
  end

  def sized?(i, %{size: size}) when (i * 8) < size, do: false
  def sized?(i, %{size: size, unit: 0}), do: i * 8 == size
  def sized?(i, %{size: size, unit: unit}), do: rem(i * 8 - size, unit) == 0

  def valid_node?(atom) do
    atom
    |> Atom.to_string
    |> String.split("@")
    |> case do
      [_, _] -> true
      _ -> false
    end
  end

  def valid_module?(atom) do
    function_exported?(atom, :module_info, 0)
  end

  def typegroup(%{module: nil, name: name}) do
    @groups_for[name]
  end
  # String.t is special-cased.
  def typegroup(%{module: String, name: :t}), do: 11
  def typegroup(_type), do: 0

  def compare(this, other) do
    this_group = Type.typegroup(this)
    other_group = Type.typegroup(other)
    cond do
      this_group > other_group -> :gt
      this_group < other_group -> :lt
      true -> group_compare(this, other)
    end
  end

  group_compare do
    # group compare for the integer block.
    def group_compare(pos_integer(), _),           do: :gt
    def group_compare(_, pos_integer()),           do: :lt
    def group_compare(_, i) when is_integer(i) and i >= 0, do: :lt
    def group_compare(_, _..b) when b >= 0,                do: :lt

    # group compare for the atom block
    def group_compare(atom(), _),                  do: :gt
    def group_compare(_, atom()),                  do: :lt
    def group_compare(module(), _),                do: :gt
    def group_compare(_, module()),                do: :lt
    def group_compare(node_type(), _),                  do: :gt
    def group_compare(_, node_type()),                  do: :lt

    # group compare for iolist
    def group_compare(iolist(), what), do: Type.Iolist.compare_list(what)
    def group_compare(what, iolist()), do: Type.Iolist.compare_list_inv(what)

    # group compare for strings
    def group_compare(%Type{module: String, name: :t, params: []}, right) do
      %Type.Bitstring{unit: 8}
      |> Type.compare(right)
      |> case do
        :eq -> :lt
        order -> order
      end
    end
    def group_compare(%Type{module: String, name: :t, params: [p]}, right) do
      lowest_idx = case p do
        i when is_integer(i) -> [i]
        range = _.._ -> range
        %Type.Union{of: ints} -> ints
      end
      |> Enum.min

      %Type.Bitstring{size: lowest_idx * 8}
      |> Type.compare(right)
      |> case do
        :eq -> :lt
        order -> order
      end
    end

    def group_compare(_, _), do: :gt
  end

  subtype do
    def subtype?(iolist(), maybe_iolist = %Type.Union{}) do
      Type.Iolist.supertype_of_iolist?(maybe_iolist)
    end
    def subtype?(%Type{module: String, name: :t, params: p}, right) do
      case p do
        [] -> Type.subtype?(binary(), right)
        [i] when is_integer(i) ->
          Type.subtype?(%Type.Bitstring{size: i * 8}, right)
        range = _.._ ->
          Enum.all?(range, &Type.subtype?(%Type.Bitstring{size: &1 * 8}, right))
        %Type.Union{of: ints} ->
          Enum.all?(ints, &Type.subtype?(%Type.Bitstring{size: &1 * 8}, right))
      end
    end
    def subtype?(left, right) when is_remote(left) do
      left
      |> Type.fetch_type!
      |> Type.subtype?(right)
    end
    def subtype?(a, b) when is_primitive(a), do: usable_as(a, b, []) == :ok
  end

  subtract do
  end

  # downconverts an arity/1 String.t(_) type to String.t()
  def normalize(type = %Type{module: String, name: :t, params: [_]}) do
    %{type | params: []}
  end
  def normalize(type), do: type
end
