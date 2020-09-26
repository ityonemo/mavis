defmodule Type.Map do
  defstruct [required: [], optional: []]

  @type optional :: {Type.t, Type.t}
  @type requirable :: {integer | atom, Type.t}

  @type t :: %__MODULE__{
    required: [requirable],
    optional: [optional]
  }

  defimpl Type.Properties do
    import Type, only: [builtin: 1]

    use Type.Impl
  end
end
