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

    use Type.Impl

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

      def usable_as(challenge, target = %List{}, meta) do
        u1 = Type.usable_as(challenge.type, target.type)
        u2 = Type.usable_as(challenge.final, target.final)

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
    end

    # can't simply forward to usable_as, because any of the encapsulated
    # types might have a usable_as rule that isn't strictly subtype?
    def subtype?(list_type, list_type), do: true
    def subtype?(_list_type, builtin(:any)), do: true
    # same nonempty is okay
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
end
