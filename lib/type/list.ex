defmodule Type.List do
  defstruct [
    nonempty: false,
    type: %Type{name: :any},
    final: []
  ]

  @type t :: %__MODULE__{
    nonempty: boolean,
    type: Type.t,
    final: Type.t
  }

  defimpl Type.Properties do
    import Type, only: :macros

    use Type

    alias Type.{List, Message, Union}

    def group_compare(%{nonempty: ne}, []), do: if ne, do: :lt, else: :gt
    def group_compare(%{nonempty: false}, %List{nonempty: true}), do: :gt
    def group_compare(%{nonempty: true}, %List{nonempty: false}), do: :lt
    def group_compare(a, b) do
      case Type.compare(a.type, b.type) do
        :eq -> Type.compare(a.final, b.final)
        ordered -> ordered
      end
    end

    usable_as do
      def usable_as(challenge = %{nonempty: false}, target = %List{nonempty: true}, meta) do
        case usable_as(challenge, %{target | nonempty: false}, meta) do
          :ok -> {:maybe, Message.make(challenge, target, meta)}
          maybe_or_error -> maybe_or_error
        end
      end

      def usable_as(challenge, builtin(:iolist), meta) do
        Type.Iolist.usable_as_iolist(challenge, meta)
      end

      def usable_as(challenge, target = %List{}, meta) do
        u1 = Type.usable_as(challenge.type, target.type, meta)
        u2 = Type.usable_as(challenge.final, target.final, meta)

        case Type.ternary_and(u1, u2) do
          :ok -> :ok
          # TODO: make this report the internal error as well.
          {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
          {:error, _} -> {:error, Message.make(challenge, target, meta)}
        end
      end
    end

    intersection do
      def intersection(%{nonempty: false}, []), do: []
      def intersection(a, b = %List{}) do
        case {Type.intersection(a.type, b.type), Type.intersection(a.final, b.final)} do
          {builtin(:none), _} -> builtin(:none)
          {_, builtin(:none)} -> builtin(:none)
          {type, final} ->
            %List{type: type, final: final, nonempty: a.nonempty or b.nonempty}
        end
      end
      def intersection(a, builtin(:iolist)), do: Type.Iolist.intersection_with(a)
    end

    # can't simply forward to usable_as, because any of the encapsulated
    # types might have a usable_as rule that isn't strictly subtype?
    def subtype?(list_type, list_type), do: true
    def subtype?(_list_type, builtin(:any)), do: true
    # same nonempty is okay
    def subtype?(list, builtin(:iolist)), do: Type.Iolist.subtype_of_iolist?(list)
    def subtype?(challenge = %{nonempty: ne_c}, target = %List{nonempty: ne_t})
      when ne_c == ne_t or ne_c do

      Type.subtype?(challenge.type, target.type) and
        Type.subtype?(challenge.final, target.final)
    end
    def subtype?(challenge, %Union{of: types}) do
      Enum.any?(types, &Type.subtype?(challenge, &1))
    end
    def subtype?(_, _), do: false
  end

  defimpl Inspect do
    import Inspect.Algebra

    import Type, only: :macros

    #########################################################
    ## SPECIAL CASES

    # override for charlist
    def inspect(list = %{final: [], type: 0..1114111}, _) do
      "#{nonempty_prefix list}charlist()"
    end
    def inspect(%{final: [], type: builtin(:any), nonempty: true}, _), do: "[...]"
    def inspect(%{final: [], type: builtin(:any)}, _), do: "list()"
    # keyword list literal syntax
    def inspect(%{
        final: [],
        nonempty: false,
        type: %Type.Tuple{elements: [k, v]}}, opts) when is_atom(k) do
      to_doc([{k, v}], opts)
    end
    def inspect(list = %{
        final: [],
        nonempty: false,
        type: type = %Type.Union{}}, opts) do
      if Enum.all?(type.of, &match?(
            %Type.Tuple{elements: [e, _]} when is_atom(e), &1)) do
        type.of
        |> Enum.reverse
        |> Enum.map(&List.to_tuple(&1.elements))
        |> to_doc(opts)
      else
        render_basic(list, opts)
      end
    end
    # keyword syntax
    def inspect(%{final: [],
                  nonempty: false,
                  type: %Type.Tuple{elements: [builtin(:atom),
                                               builtin(:any)]}}, _) do
      "keyword()"
    end
    def inspect(%{final: [],
                  nonempty: false,
                  type: %Type.Tuple{elements: [builtin(:atom),
                                               type]}}, opts) do
      concat(["keyword(", to_doc(type, opts), ")"])
    end

    ##########################################################
    ## GENERAL CASES

    def inspect(list = %{final: []}, opts), do: render_basic(list, opts)
    # check for maybe_improper
    def inspect(list = %{final: final = %Type.Union{}}, opts) do
      if [] in final.of do
        render_maybe_improper(list, opts)
      else
        render_improper(list, opts)
      end
    end
    def inspect(list = %{type: builtin(:any), final: builtin(:any)}, _) do
      "#{nonempty_prefix list}maybe_improper_list()"
    end
    def inspect(list, opts), do: render_improper(list, opts)

    defp render_basic(list, opts) do
      nonempty_prefix = if list.nonempty do
        "..., "
      else
        ""
      end

      concat(["[", nonempty_prefix, to_doc(list.type, opts), "]"])
    end

    defp render_maybe_improper(list, opts) do
      improper_final = Enum.into(list.final.of -- [[]], %Type.Union{})
      concat(["#{nonempty_prefix list}maybe_improper_list(",
              to_doc(list.type, opts), ", ",
              to_doc(improper_final, opts), ")"])
    end

    defp render_improper(list = %{nonempty: true}, opts) do
      concat(["nonempty_improper_list(",
              to_doc(list.type, opts), ", ",
              to_doc(list.final, opts), ")"])
    end

    defp nonempty_prefix(list) do
      if list.nonempty, do: "nonempty_", else: ""
    end
  end
end
