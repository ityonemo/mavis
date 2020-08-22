defmodule Type.AsBoolean do
  @enforce_keys [:for]
  defstruct [:for]

  @type t :: %__MODULE__{for: Type.t}

  defimpl Type.Typed do
    import Type

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(_, _), do: :type_error
  end
end
