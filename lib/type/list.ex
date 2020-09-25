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

  defimpl Type.Typed do
    import Type, only: [builtin: 1]

    use Type.Impl

    alias Type.{List, Message}

    def group_order(%{nonempty: ne}, []), do: not ne
    def group_order(%{nonempty: false}, %List{nonempty: true}), do: true
    def group_order(%{nonempty: true}, %List{nonempty: false}), do: false
    def group_order(a, b) do
      case {Type.order(a.type, b.type), Type.order(b.type, a.type)} do
        {true, false} -> true
        {false, true} -> false
        {true, true} ->
          Type.order(a.final, b.final)
      end
    end

    def usable_as(type, type, _meta), do: :ok
    def usable_as(_challenge, builtin(:any), _meta), do: :ok

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

    def usable_as(challenge, target, meta) do
      {:error, Message.make(challenge, target, meta)}
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
    def subtype?(_, _), do: false
  end
end
