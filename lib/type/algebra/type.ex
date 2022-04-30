defimpl Type.Algebra, for: Type do

  alias Type.Helpers
  alias Type.Message

  require Helpers

  @group_for %{
    none: 0, neg_integer: 1, non_neg_integer: 1, pos_integer: 1,
    float: 2, node: 3, module: 3, atom: 3, reference: 4, port: 6,
    pid: 7, iolist: 10, any: 12}
  @builtins Map.keys(@group_for)

  def typegroup(%Type{module: nil, name: name}) when name in @builtins do
    @group_for[name]
  end
  def typegroup(%Type{module: String, name: :t}), do: 11

  import Type, only: :macros

  def compare(same, same), do: :eq
  def compare(_, %Type{module: nil, name: :any}), do: :lt
  def compare(iolist(), t), do: compare_iolist(t)
  def compare(ltype, rtype) do
    lgroup = typegroup(ltype)
    rgroup = Type.typegroup(rtype)
    case {lgroup, rgroup, ltype, rtype} do
      {lgroup, rgroup, _, _} when lgroup < rgroup -> :lt
      {lgroup, rgroup, _, _} when lgroup > rgroup -> :gt
      {_, _, _, %Type.Union{of: [first | _]}} ->
        result = Type.compare(ltype, first)
        if result == :eq, do: :lt, else: result
      _ ->
        compare_internal(ltype, rtype)
    end
  end

  def compare_internal(type([...]), l) when is_list(l), do: :gt
  def compare_internal(pos_integer(), neg_integer()), do: :gt
  def compare_internal(pos_integer(), i) when is_integer(i), do: :gt
  def compare_internal(pos_integer(), _.._), do: :gt
  def compare_internal(neg_integer(), i) when i < 0, do: :gt
  def compare_internal(neg_integer(), _..b) when b < 0, do: :gt
  def compare_internal(float(), f) when is_float(f), do: :gt
  def compare_internal(atom(), atom) when is_atom(atom), do: :gt
  def compare_internal(atom(), type(node())), do: :gt
  def compare_internal(atom(), module()), do: :gt
  def compare_internal(module(), type(node())), do: :gt
  def compare_internal(module(), atom) when is_atom(atom), do: :gt
  def compare_internal(type(node()), atom) when is_atom(atom), do: :gt
  def compare_internal(_, _), do: :lt

  @iotype %Type.Union{of: [binary(), iolist(), byte()]}
  @iofinal %Type.Union{of: [binary(), []]}
  @iolist %Type.Union{of: [%Type.List{type: @iotype, final: @iofinal}, []]}

  defp compare_iolist(t = %Type.Union{of: types}) do
    if iolist() in types, do: :lt, else: Type.compare(@iolist, t)
  end
  defp compare_iolist(t) do
    Type.compare(@iolist, t)
  end

  Helpers.algebra_merge_fun(__MODULE__, :merge_internal)

  def merge_internal(neg_integer(), n) when is_integer(n) and n < 0, do: {:merge, [neg_integer()]}
  def merge_internal(neg_integer(), _..n) when n < 0, do: {:merge, [neg_integer()]}
  def merge_internal(pos_integer(), n) when is_integer(n) and n > 0, do: {:merge, [pos_integer()]}
  def merge_internal(pos_integer(), 0.._), do: {:merge, [pos_integer(), 0]}
  def merge_internal(pos_integer(), a.._) when a > 0, do: {:merge, [pos_integer()]}
  def merge_internal(pos_integer(), a..b) when b > 0, do: {:merge, [pos_integer(), a..0]}
  def merge_internal(float(), f) when is_float(f), do: {:merge, [float()]}
  def merge_internal(module(), a) when is_atom(a), do: {:merge, [module()]}
  def merge_internal(atom(), module()), do: {:merge, [atom()]}
  def merge_internal(atom(), type(node())), do: {:merge, [atom()]}
  def merge_internal(atom(), a) when is_atom(a), do: {:merge, [atom()]}
  def merge_internal(type(node()), a) when is_atom(a) do
    if Type.Algebra.Atom.valid_node?(a), do: {:merge, [type(node())]}, else: :nomerge
  end
  def merge_internal(iolist(), type) do
    case intersect_internal(iolist(), type) do
      ^type -> {:merge, [iolist()]}
      _ -> :nomerge
    end
  end
  def merge_internal(_, _), do: :nomerge

  Helpers.algebra_intersection_fun(__MODULE__, :intersect_internal)

  def intersect_internal(any(), type), do: type
  def intersect_internal(type([...]), []), do: none()
  def intersect_internal(type([...]), l) when is_list(l), do: l
  def intersect_internal(neg_integer(), i) when is_integer(i) and i < 0, do: i
  def intersect_internal(neg_integer(), a..b) when b < 0, do: a..b
  def intersect_internal(pos_integer(), i) when is_integer(i) and i > 0, do: i
  def intersect_internal(pos_integer(), a..b) when a > 0, do: a..b
  def intersect_internal(pos_integer(), _..1), do: 1
  def intersect_internal(pos_integer(), _..a) when a > 1, do: 1..a
  def intersect_internal(float(), f) when is_float(f), do: f
  def intersect_internal(atom(), a) when is_atom(a), do: a
  def intersect_internal(atom(), type(node())), do: type(node())
  def intersect_internal(atom(), module()), do: module()
  def intersect_internal(module(), a) when is_atom(a), do: a
  def intersect_internal(type(node()), a) when is_atom(a) do
    if Type.Algebra.Atom.valid_node?(a), do: a, else: none()
  end
  def intersect_internal(iolist(), type), do: Type.intersect(@iolist, type)
  def intersect_internal(type(String.t()), binary) when is_binary(binary) do
    if String.valid?(binary), do: binary, else: none()
  end
  def intersect_internal(_, _), do: none()

  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)

  def subtype_internal(_, _), do: false

  Helpers.algebra_usable_as_fun(__MODULE__, :usable_as_internal)
  def usable_as_internal(any(), target, meta) do
    {:maybe, [Message.make(any(), target, meta)]}
  end
  def usable_as_internal(pos_integer(), target, meta)
      when is_integer(target) and target > 0 do
    {:maybe, [Message.make(pos_integer(), target, meta)]}
  end
  def usable_as_internal(neg_integer(), target, meta)
      when is_integer(target) and target < 0 do
    {:maybe, [Message.make(neg_integer(), target, meta)]}
  end
  def usable_as_internal(pos_integer(), target = _..n, meta) when n > 0 do
    {:maybe, [Message.make(pos_integer(), target, meta)]}
  end
  def usable_as_internal(neg_integer(), target = n.._, meta) when n < 0 do
    {:maybe, [Message.make(neg_integer(), target, meta)]}
  end
  def usable_as_internal(type(node()), a, meta) when is_atom(a) do
    a
    |> Atom.to_string
    |> String.split("@")
    |> case do
      [_, _] -> {:maybe, [Message.make(type(node()), a, meta)]}
      _ -> {:error, Message.make(type(node()), a, meta)}
    end
  end
  def usable_as_internal(type(node()), atom(), _), do: :ok
  def usable_as_internal(module(), atom(), _), do: :ok
  def usable_as_internal(module(), a, meta) when is_atom(a) do
    {:maybe, [Message.make(module(), a, meta)]}
  end
  def usable_as_internal(atom(), a, meta) when is_atom(a) do
    {:maybe, [Message.make(atom(), a, meta)]}
  end
  def usable_as_internal(atom(), type(node()), meta) do
    {:maybe, [Message.make(atom(), type(node()), meta)]}
  end
  def usable_as_internal(atom(), module(), meta) do
    {:maybe, [Message.make(atom(), module(), meta)]}
  end
  def usable_as_internal(iolist(), t, meta) do
    Type.usable_as(@iolist, t, meta)
  end
  def usable_as_internal(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end
end
