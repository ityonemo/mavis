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
    import Type, only: :macros

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
