defmodule Type.AsBoolean do

  # honestly I don't know wtf to do about this
  # typeclass.

  @enforce_keys [:for]
  defstruct [:for]

  @type t :: %__MODULE__{for: Type.t}

  defimpl Type.Typed do
    import Type, only: [builtin: 1]
  end
end
