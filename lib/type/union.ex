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

  use Type.Helpers, default_subtype: true

  alias Type.Message

  def typegroup(%{of: [first | _]}), do: Type.typegroup(first)

  def compare(%{of: list1}, %Type.Union{of: list2}) do\
    do_compare(list1, list2)
  end

  def compare(%{of: [first | _]}, right) do
    result = Type.compare(first, right)
    if result == :eq, do: :gt, else: result
  end

  defp do_compare([lhead | ltail], [rhead | rtail]) do\
    case Type.compare(lhead, rhead) do
      :eq -> do_compare(ltail, rtail)
      other -> other
    end
  end
  defp do_compare([], _), do: :lt
  defp do_compare(_, []), do: :gt

  def intersect(lunion, runion = %Type.Union{}) do
    lunion.of
    |> Enum.map(&intersect(runion, &1))
    |> Type.union
  end

  def intersect(union = %{}, rtype) do
    union.of
    |> Enum.map(&Type.intersect(&1, rtype))
    |> Type.union
  end

  @spec merge(t, Type.t) :: t
  @doc false
  def merge(_, _), do: raise "type merging with unions is disallowed"

  # checks if a union OR its underlying list is valid.  Useful for debugging
  # purposes only.  A union is invalid if any of the following are true:
  # - it's an empty list
  # - it's not in sorted order
  # - if any of its children are pairwise mergeable.
  def _valid?(%Type.Union{of: list}), do: _valid?(list)
  def _valid?([]), do: false
  def _valid?([%Type.Union{} | _]), do: false
  def _valid?([_]), do: true
  def _valid?([a, b | rest]) do
    case Type.compare(a, b) do
      :gt ->
        _pairwise_unmergeable(a, [b | rest]) and _valid?([b | rest])
      _ -> false
    end
  end

  defp _pairwise_unmergeable(_, []), do: true
  defp _pairwise_unmergeable(a, [b | rest]) do
    (Type.merge(a, b) == :nomerge) and _pairwise_unmergeable(a, rest)
  end

  def usable_as(challenge = %{of: types}, target, meta) do
    types
    |> Enum.map(&Type.usable_as(&1, target, meta))
    |> Enum.reduce(&Type.ternary_maybe/2)
    |> Message._rebrand(challenge, target)
  end

  defimpl Collectable do
    alias Type.Union
    import Type, only: :macros

    @type collector :: (list(Type.t), :done | :halt | {:cont, list(Type.t)} -> Type.t | :ok)

    @impl true
    @spec into(Union.t) :: {Union.t, collector}
    def into(%Union{of: types}) do
      {types, &collector/2}
    end

    @env Mix.env()

    defmacrop assert_valid(list_ast) do
      %{file: file, line: line} = __CALLER__
      if @env == :test do
        quote do
          list = unquote(list_ast) # this might need execution, let's only do it once.
          unless Type.Union._valid?(list), do: raise "an invalid list detected: #{inspect list} #{unquote(file)}:#{unquote(line)}"
          list
        end
      else
        list_ast
      end
    end

    defp collector(_, :halt), do: :ok
    defp collector([], :done), do: none()
    defp collector([type], :done), do: type
    defp collector(types, :done) when is_list(types), do: %Union{of: assert_valid types}
    defp collector(types_so_far, {:cont, %Type.Union{of: types}}) do
      Enum.reduce(types, types_so_far, &merge_into_list/2)
    end
    defp collector(types_so_far, {:cont, type}) do
      merge_into_list(type, types_so_far)
    end

    defp merge_into_list(type, into_list, so_far_asc \\ [])
    defp merge_into_list(type, [], so_far_asc), do: slot_into_list(type, Enum.reverse(so_far_asc))
    defp merge_into_list(type, [first | rest], so_far_asc) do
      case Type.merge(type, first) do
        :nomerge ->
          merge_into_list(type, rest, [first | so_far_asc])
        {:merge, types} ->
          list_desc = Enum.reverse(so_far_asc, rest)
          Enum.reduce(types, list_desc, &merge_into_list(&1, &2))
      end
    end

    # slots a type into a list of types.  Result will always be sorted.
    @spec slot_into_list(Type.t, [Type.t]) :: [Type.t]
    defp slot_into_list(type, list_asc, so_far_desc \\ [])
    defp slot_into_list(type, [], so_far_desc) do
      Enum.reverse(so_far_desc, [type])
    end
    defp slot_into_list(type, [first | rest] = all, so_far_desc) do
      case Type.compare(type, first) do
        :gt -> Enum.reverse(so_far_desc, [type | all])
        :lt ->
          slot_into_list(type, rest, [first | so_far_desc])
      end
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
          keyword_or_list(t, opts)
      end
    catch
      :default ->
        ["list(", to_doc(t, opts), ")"]
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

    defp make_pairs([], _, [", " | acc], _opts), do: acc
    defp make_pairs([atom | rest], value, acc, opts) when is_atom(atom) do
      make_pairs(rest, value, [", ", to_doc(value, opts), "#{atom}: " | acc], opts)
    end
    defp make_pairs(_, _, _, _), do: nil

    defp keyword_or_list(type = %Type.Tuple{elements: [key, value], fixed: true}, opts) do
      case key do
        atom when is_atom(atom) ->
          ["type([#{key}: ", to_doc(value, opts), "])"]
        %Type.Union{of: maybe_atoms} ->
          if pairs = make_pairs(maybe_atoms, value, [], opts) do
            ["type([" | Enum.reverse(pairs, ["])"])]
          else
            keyword_give_up([type], opts)
          end
        _other ->
          keyword_give_up([type], opts)
      end
    end
    defp keyword_or_list(%Type.Union{of: maybe_keyword_tuples}, opts) do
      keyword_or_list_stub(maybe_keyword_tuples, maybe_keyword_tuples, ["type(["], opts)
    end
    defp keyword_or_list(type, opts) do
      keyword_give_up([type], opts)
    end

    defp keyword_or_list_stub(_whole, [], [", " | acc], _), do: Enum.reverse(["])" | acc])

    defp keyword_or_list_stub(whole, [%Type.Tuple{elements: [key, value], fixed: true} | rest], acc, opts) do
      case key do
        key when is_atom(key) ->
          keyword_or_list_stub(whole, rest, [", ", to_doc(value, opts), "#{key}: " | acc], opts)

        %Type.Union{of: maybe_atoms} ->
          if Enum.all?(maybe_atoms, &is_atom/1) do
            pairs = Enum.flat_map(maybe_atoms, &["#{&1}: ", to_doc(value, opts), ", "])

            keyword_or_list_stub(whole, rest, Enum.reverse(pairs, acc), opts)
          else
            keyword_give_up(whole, opts)
          end

        _other ->
          keyword_give_up(whole, opts)
      end
    end
    defp keyword_or_list_stub(whole, _not_a_keyword, _acc, opts) do
      keyword_give_up(whole, opts)
    end

    defp keyword_give_up(whole, opts) do
      content = whole
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(" <|> ")

      ["list(" | content] ++ [")"]
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
