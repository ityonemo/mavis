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
    import Type

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(%{return: from}, %Type.Function{params: :any, return: into}) do
      Type.coercion(from, into)
    end
    def coercion(%{params: from_params, return: from_return},
      %Type.Function{params: into_params, return: into_return}) do

      from_params
      |> Enum.zip(into_params)
      |> Enum.map(fn {from, into} -> Type.coerce(from, into) end)
      |> Enum.reduce(:type_ok, )

    end

    def coercion(_, _), do: :type_error
  end
end
