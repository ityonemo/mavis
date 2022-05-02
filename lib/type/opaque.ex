defmodule Type.Opaque do
  @moduledoc """
  A wrapper for opaqueness.
  """

  @enforce_keys [:module, :name, :params, :type]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
    module: module,
    name: atom,
    params: [Type.t],
    type: Type.t
  }

  use Type.Helpers

  def typegroup(%{type: child}) do
    Type.typegroup(child)
  end

  def subtype?(_, _), do: false

  defimpl Inspect do
    import Inspect.Algebra
    def inspect(opaque, opts) do
      params = opaque.params
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(", ")

      concat(
        ["opaque(#{inspect opaque.module}.#{opaque.name}("] ++
        params ++
        ["), ", to_doc(opaque.type, opts), ")"])
    end
  end
end
