defmodule Type.Function.Branch do
  use Type.Helpers

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: :any]

  @type t :: %__MODULE__{
    params: [Type.t] | :any | pos_integer,
    return: Type.t
  }
  
end
