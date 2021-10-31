defmodule Type.Function.Branched do
  use Type.Helpers

  @enforce_keys [:branches]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    branches: [Type.Function.t]
  }

  @spec new([Type.Function.t]) :: t
  def new(fn_list) do
    %__MODULE__{branches: Enum.sort(fn_list, {:desc, Type})}
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{params: :any, return: return}, opts) do
      concat(["type((... -> ", to_doc(return, opts), "))"])
    end
  end
end
