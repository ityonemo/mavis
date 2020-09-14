defmodule Type.Tuple do
  @enforce_keys [:elements]
  defstruct @enforce_keys

  @type t :: %__MODULE__{elements: [Type.t] | :any}

  defimpl Type.Typed do
    import Type, only: [builtin: 1]

    use Type.Impl

    def group_order(%{elements: e1}, %{elements: e2}) when length(e1) > length(e2), do: true
    def group_order(%{elements: e1}, %{elements: e2}) when length(e1) < length(e2), do: false
    def group_order(tuple1, tuple2) do
      tuple1.elements
      |> Enum.zip(tuple2.elements)
      |> Enum.any?(fn {t1, t2} ->
        # they can't be equal
        Type.order(t1, t2) and not Type.order(t2, t1)
      end)
    end

    alias Type.Tuple

    def coercion(_, builtin(:any)),                 do: :type_ok

    # tuples always coerce into "any tuples"
    def coercion(_, %Tuple{elements: :any}),        do: :type_ok
    # "any tuples" maybe coerce into other tuples
    def coercion(%Tuple{elements: :any}, %Tuple{}), do: :type_maybe

    # generic tuple lengths must match
    def coercion(%Tuple{elements: from}, %Tuple{elements: into})
        when length(from) == length(into) do

      from
      |> Enum.zip(into)
      |> Enum.map(&Type.coercion/1)
      |> Type.collect
    end

    def coercion(_, _), do: :type_error
  end
end
