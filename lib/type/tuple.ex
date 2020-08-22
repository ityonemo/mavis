defmodule Type.Tuple do
  @enforce_keys [:elements]
  defstruct @enforce_keys

  @type t :: %__MODULE__{elements: [Type.t] | :any}

  defimpl Type.Typed do
    import Type

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(_, _), do: :type_error
  end
end
