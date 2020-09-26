defmodule Type.Tuple do
  @enforce_keys [:elements]
  defstruct @enforce_keys

  @type t :: %__MODULE__{elements: [Type.t] | :any}

  defimpl Type.Properties do
    import Type, only: :macros

    use Type.Impl

    def group_compare(%{elements: e1}, %{elements: e2}) when length(e1) > length(e2), do: :gt
    def group_compare(%{elements: e1}, %{elements: e2}) when length(e1) < length(e2), do: :lt
    def group_compare(tuple1, tuple2) do
      tuple1.elements
      |> Enum.zip(tuple2.elements)
      |> Enum.each(fn {t1, t2} ->
        compare = Type.compare(t1, t2)
        unless compare == :eq do
          throw compare
        end
      end)
      :eq
    catch
      compare when compare in [:gt, :lt] -> compare
    end

    alias Type.{Message, Tuple, Union}

    usable_as do
      # any tuple can be used as an any tuple
      def usable_as(_, %Tuple{elements: :any}, _meta), do: :ok

      # the any tuple maybe can be used as any tuple
      def usable_as(challenge = %{elements: :any}, target = %Tuple{}, meta) do
        {:maybe, [Message.make(challenge, target, meta)]}
      end

      def usable_as(challenge = %{elements: ce}, target = %Tuple{elements: te}, meta)
          when length(ce) == length(te) do
        ce
        |> Enum.zip(te)
        |> Enum.map(fn {c, t} -> Type.usable_as(c, t, meta) end)
        |> Enum.reduce(&Type.ternary_and/2)
        |> case do
          :ok -> :ok
          # TODO: make our type checking nested, should be possible here.
          {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
          {:error, _} -> {:error, Message.make(challenge, target, meta)}
        end
      end
    end

    # can't simply forward to usable_as, because any of the encapsulated
    # types might have a usable_as rule that isn't strictly subtype?
    def subtype?(tuple_type, tuple_type), do: true
    def subtype?(_tuple_type, builtin(:any)), do: true
    def subtype?(_tuple_type, %Tuple{elements: :any}), do: true
    # same nonempty is okay
    def subtype?(%{elements: el_c}, %Tuple{elements: el_t})
      when length(el_c) == length(el_t) do

      el_c
      |> Enum.zip(el_t)
      |> Enum.all?(fn {c, t} -> Type.subtype?(c, t) end)

    end
    def subtype?(tuple, %Union{of: types}) do
      Enum.any?(types, &Type.subtype?(tuple, &1))
    end
    def subtype?(_, _), do: false
  end
end
