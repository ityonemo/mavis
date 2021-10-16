defmodule Type.Subtraction do
  @enforce_keys [:base, :exclude]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    base: Type.t,
    exclude: Type.t
  }

  defimpl Type.Algebra do
    def subtract(a, b) do
      raise "unimplemented"
    end
  end
end
