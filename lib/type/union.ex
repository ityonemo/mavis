defmodule Type.Union do
  @moduledoc """
  Represents the Union of two or more types.

  The associated struct has one field:
  - `:of` which is a list of all types that are being unioned.

  For performance purposes, Union keeps its subtypes in
  reverse-type-order.

  Type.Union implements both the enumerable protocol and the
  collectable protocol; if you collect into a union, it will return
  a `t:Type.t/0` result in general; it might not be a Type.Union struct:

  ```
  iex> Enum.into([1, 3], %Type.Union{})
  %Type.Union{of: [3, 1]}

  iex> inspect %Type.Union{of: [3, 1]}
  "1 | 3"

  iex> Enum.into([1..10, 11..20], %Type.Union{})
  1..20
  ```
  """

  defstruct [of: []]
  @type t :: %__MODULE__{of: [Type.t, ...]}
  @type t(type) :: %__MODULE__{of: [type, ...]}

  use Type.Helpers

  def typegroup(%{of: [first | _]}), do: Type.typegroup(first)

  # note that this only gets called when the first items match
  def compare(%{of: [first | _]}, right) do
    result = Type.compare(first, right)
    if result == :eq, do: :gt, else: result
  end

  def intersection(lunion, runion = %Type.Union{}) do
    lunion.of
    |> Enum.map(&intersection(runion, &1))
    |> Type.union
  end

  def intersection(union = %{}, rtype) do
    union.of
    |> Enum.map(&Type.intersection(&1, rtype))
    |> Type.union
  end

  @spec collapse(t) :: Type.t
  @doc false
  def collapse(%__MODULE__{of: []}) do
    import Type, only: :macros
    Type.none()
  end
  def collapse(%__MODULE__{of: [singleton]}), do: singleton
  def collapse(union), do: union

  @spec merge(t, Type.t) :: t
  @doc false
  # special case merging a union with another union.
  def merge(%{of: into}, %__MODULE__{of: list}) do
    %__MODULE__{of: merge_raw(into, list)}
  end
  def merge(%{of: list}, type) do
    %__MODULE__{of: merge_raw(list, [type])}
  end

  # merges: types in argument1 into the list of argument2
  # argument2 is required to be in DESCENDING order
  # returns the fully merged types, in ASCENDING order
  @spec merge_raw([Type.t], [Type.t]) :: [Type.t]
  defp merge_raw(list, [head | rest]) do
    {new_list, retries} = fold(head, Enum.reverse(list), [])
    merge_raw(new_list, retries ++ rest)
  end
  defp merge_raw(list, []) do
    Enum.sort(list, {:desc, Type})
  end

  # folds argument 1 into the list of argument2.
  # argument 3, which is the stack, contains the remaining types in ASCENDING order.
  @spec fold(Type.t, [Type.t], [Type.t]) :: {[Type.t], [Type.t]}
  defp fold(type, [type | rest], stack) do
    fold(type, rest, stack)
  end
  defp fold(type, [head | rest], stack) do
    with order when order in [:gt, :lt] <- Type.compare(head, type),
         retries when is_list(retries) <- type_merge(order, head, type) do
      {unroll(rest, stack), retries}
    else
      :eq ->
        {unroll(rest, [head | stack]), []}
      :nomerge ->
        fold(type, rest, [head | stack])
    end
  end
  defp fold(type, [], stack) do
    {[type | stack], []}
  end

  defp unroll([], stack), do: stack
  defp unroll([head | rest], stack), do: unroll(rest, [head | stack])

  defdelegate type_merge(order, head, type), to: Type.Union.Merge

#  #defimpl Type.Algebra do
#  #  import Type, only: :macros
#  #  import Type.Helpers
##
#  #  alias Type.Union
##
#  #  def compare(union, %Type.Function.Var{constraint: type}) do
#  #    case Type.compare(union, type) do
#  #      :eq -> :gt
#  #      order -> order
#  #    end
#  #  end
#  #  def compare(union, %Type.Opaque{type: type}) do
#  #    case Type.compare(union, type) do
#  #      :eq -> :gt
#  #      order -> order
#  #    end
#  #  end
#  #  def compare(%{of: llist}, %Union{of: rlist}) do
#  #    union_list_compare(llist, rlist)
#  #  end
#  #  def compare(%{of: [first | _]}, type) do
#  #    case Type.compare(first, type) do
#  #      :eq -> :gt
#  #      order -> order
#  #    end
#  #  end
##
#  #  defp union_list_compare([], []), do: :eq
#  #  defp union_list_compare([], _), do: :lt
#  #  defp union_list_compare(_, []), do: :gt
#  #  defp union_list_compare([lh | lrest], [rh | rrest]) do
#  #    case Type.compare(lh, rh) do
#  #      :eq -> union_list_compare(lrest, rrest)
#  #      order -> order
#  #    end
#  #  end
##
#  #  def typegroup(%{of: [first | _]}) do
#  #    Type.Algebra.typegroup(first)
#  #  end
##
#  #  def usable_as(type, type, _meta), do: :ok
#  #  def usable_as(challenge, target, meta) do
#  #    challenge.of
#  #    |> Enum.map(&Type.usable_as(&1, target, meta))
#  #    |> Enum.reduce(fn
#  #      # TO BE REPLACED WITH SOMETHING MORE SOPHISTICATED.
#  #      :ok, :ok                 -> :ok
#  #      :ok, {:maybe, _}         -> {:maybe, nil}
#  #      :ok, {:error, _}         -> {:maybe, nil}
#  #      {:maybe, _}, :ok         -> {:maybe, nil}
#  #      {:error, _}, :ok         -> {:maybe, nil}
#  #      {:maybe, _}, {:maybe, _} -> {:maybe, nil}
#  #      {:maybe, _}, {:error, _} -> {:maybe, nil}
#  #      {:error, _}, {:maybe, _} -> {:maybe, nil}
#  #      {:error, _}, {:error, _} -> {:error, nil}
#  #    end)
#  #    |> case do
#  #      :ok -> :ok
#  #      {:maybe, _} -> {:maybe, [Type.Message.make(challenge, target, meta)]}
#  #      {:error, _} -> {:error, Type.Message.make(challenge, target, meta)}
#  #    end
#  #  end
##
#  #  subtype do
#  #    def subtype?(%{of: types}, target) do
#  #      Enum.all?(types, &Type.subtype?(&1, target))
#  #    end
#  #  end
##
#  #  subtract do
#  #    def subtract(%{of: types}, subtrahend) do
#  #      {s, w} = types
#  #      |> Enum.map(&Type.subtract(&1, subtrahend))
#  #      |> Enum.reject(&(&1 == none()))
#  #      |> Enum.split_with(&match?(%Type.Subtraction{}, &1))
##
#  #      base = Enum.into(w ++ Enum.map(s, &(&1.base)), %Type.Union{})
#  #      exclude = s |> Enum.map(&(&1.exclude)) |> Enum.into(%Type.Union{})
##
#  #      if s == [], do: base, else: %Type.Subtraction{base: base, exclude: exclude}
#  #    end
#  #  end
##
#  #  def normalize(%{of: types}) do
#  #    types
#  #    |> Enum.map(&Type.normalize/1)
#  #    |> Enum.into(%Type.Union{})
#  #  end
#  #end
#
  defimpl Collectable do
    alias Type.Union

    def into(original) do
      collector_fun = fn
        union, {:cont, elem} ->
          Union.merge(union, elem)
        union, :done -> Union.collapse(union)
        _set, :halt -> :ok
      end

      {original, collector_fun}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    import Type, only: :macros

    def inspect(%{of: types}, opts) do
      cond do
        [] in types ->
          {lists, nonlists} = Enum.split_with(types -- [[]], &match?(%Type.List{}, &1))

          lists
          |> Enum.map(&emptify(&1, opts))
          |> Enum.intersperse([" <|> "])
          |> Enum.flat_map(&Function.identity/1)
          |> Kernel.++(Enum.map(nonlists, &(to_doc(&1, opts))))
          |> concat

        # override for boolean
        rest = type_has(types, [true, false]) ->
          override(rest, :boolean, opts)

        # override for identifier
        rest = type_has(types, [reference(), port(), pid()]) ->
          override(rest, :identifier, opts)

        # override for iodata
        rest = type_has(types, [iolist(), %Type.Bitstring{size: 0, unit: 8}]) ->
          override(rest, :iodata, opts)

        # override for number
        rest = type_has(types, [float(), neg_integer(), 0, pos_integer()]) ->
          override(rest, :number, opts)

        # override for integers
        rest = type_has(types, [neg_integer(), 0, pos_integer()]) ->
          override(rest, :integer, opts)

        # override for timeout
        rest = type_has(types, [0, pos_integer(), :infinity]) ->
          override(rest, :timeout, opts)

        # override for non_neg_integer
        rest = type_has(types, [0, pos_integer()]) ->
          override(rest, :non_neg_integer, opts)

        rest = type_has(types, [-1..0, pos_integer()]) ->
          type = override(rest, :non_neg_integer, opts)
          concat(["-1", " <|> ", type])

        (range = Enum.find(types, &match?(_..0, &1))) && pos_integer() in types ->
          type = types
          |> Kernel.--([range, pos_integer()])
          |> override(:non_neg_integer, opts)

          concat(["#{range.first}..-1", " <|> ", type])

        true -> normal_inspect(types, opts)
      end
    end

    defp emptify(%Type.List{type: t, final: []}, opts) do
      case t do
        any() ->
          ["list()"]
        0..0x10_FFFF ->
          ["charlist()"]
        type({atom(), any()}) ->
          ["keyword()"]
        type({atom(), kwt}) ->
          ["keyword(", to_doc(kwt, opts), ")"]
        _ ->
          t
          |> maybe_keyword
          |> Enum.sort_by(&elem(&1, 0))
          |> Enum.map(fn {a, t} -> [to_doc(t, opts), "#{a}: "] end)
          |> Enum.intersperse([", "])
          |> Enum.flat_map(&Function.identity/1)
          |> Enum.reverse(["])"])
          |> List.insert_at(0, "type([")
      end
    catch
      :default ->
        ["type([", to_doc(t, opts), "])"]
    end

    defp emptify(%Type.List{type: any(), final: any()}, _opts) do
      ["maybe_improper_list()"]
    end
    defp emptify(%Type.List{type: ltype, final: %Type.Union{of: ftypes}}, opts) do
      ftype = Type.union(ftypes -- [[]])
      ["maybe_improper_list(", to_doc(ltype, opts), ", ", to_doc(ftype, opts), ")"]
    end
    defp emptify(%Type.List{type: ltype, final: rtype}, opts) do
      if Type.subtype?([], rtype) do
        ["maybe_improper_list(", to_doc(ltype, opts), ",", to_doc(rtype, opts), ")"]
      else
        ["nonempty_improper_list(", to_doc(ltype, opts), ",", to_doc(rtype, opts), ")"]
      end
    end

    defp type_has(types, query) do
      if Enum.all?(query, &(&1 in types)), do: types -- query
    end

    defp override([], name, _opts) do
      "#{name}()"
    end
    defp override(types, name, opts) do
      concat(["#{name}()", " <|> ",
        to_doc(%Type.Union{of: types}, opts)])
    end

    defp normal_inspect(list, opts) do
      list
      |> Enum.reverse
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(" <|> ")
      |> concat
    end

    defp maybe_keyword(%Type.Tuple{elements: [a, t], fixed: true}) when is_atom(a) do
      [{a, t}]
    end

    defp maybe_keyword(%Type.Tuple{elements: [%Type.Union{of: atoms}, t], fixed: true}) do
      Enum.map(atoms, fn
        atom when is_atom(atom) -> {atom, t}
        _ -> throw :default
      end)
    end

    defp maybe_keyword(%Type.Union{of: types}) do
      Enum.flat_map(types, &maybe_keyword/1)
    end

    defp maybe_keyword(_), do: throw :default

  end
end
