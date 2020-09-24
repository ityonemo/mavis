defmodule Type.Map do
  defstruct [kv: []]

  @type optional :: {Type.t, Type.t}
  @type requirable :: {integer | atom, Type.t}
  @type kv_spec :: {:required, requirable} | {:optional, optional}

  # note that the left-to-right order of map specs is important
  # and that the leftmost values take precedence when they overlap.

  # TODO: test this
  @type t :: %__MODULE__{
    kv: [kv_spec]
  }

  defimpl Type.Typed do
    import Type, only: [builtin: 1]

    use Type.Impl

    def group_order(_, _), do: raise "the dead"

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(_, _), do: :type_error
  end
end
