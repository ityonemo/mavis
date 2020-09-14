defmodule Type.Function do

  @moduledoc """
  represents a function type.  Note that coercion of a function type
  operates in the *opposite* direction as
  """

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: []]

  @type t :: %__MODULE__{
    params: [Type.t] | :any,
    return: Type.t
  }

  def from_spec({:"::", _, [header, return]}, context) do
    {name, _, params} = header
    {name, %__MODULE__{
      params: Enum.map(params, &Type.of(&1, context)),
      return: Type.of(return, context)
    }}
  end

  defimpl Type.Typed do
    import Type, only: [builtin: 1]

    use Type.Impl

    def group_order(%{params: :any, return: r1}, %{params: :any, return: r2}) do
      Type.order(r1, r2)
    end
    def group_order(%{params: :any}, _), do: true
    def group_order(_, %{params: :any}), do: false
    def group_order(%{params: p1}, %{params: p2})
        when length(p1) < length(p2), do: true
    def group_order(%{params: p1}, %{params: p2})
        when length(p1) > length(p2), do: false
    def group_order(f1, f2) do
      [f1.return | f1.params]
      |> Enum.zip([f2.return | f2.params])
      |> Enum.any?(fn {t1, t2} ->
        # they can't be equal
        Type.order(t1, t2) and not Type.order(t2, t1)
      end)
    end

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(%{params: :any, return: from_return},
      %Type.Function{params: into_params, return: into_return}) do

      return_coercion = Type.coercion(from_return, into_return)

      case into_params do
        :any -> return_coercion
        _ -> Type.collect([:type_maybe, return_coercion])
      end
    end
    def coercion(%{return: from}, %Type.Function{params: :any, return: into}) do
      Type.coercion(from, into)
    end
    def coercion(%{params: from_params, return: from_return},
      %Type.Function{params: into_params, return: into_return})
      when length(from_params) == length(into_params) do

      # cross the returns and parameters.  (see `coercion.md`)
      [from_return | into_params]
      |> Enum.zip([into_return | from_params])
      |> Enum.map(&Type.coercion/1)
      |> Type.collect
    end

    def coercion(_, _), do: :type_error
  end
end
