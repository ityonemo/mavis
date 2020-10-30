defmodule Type.Inference.Api do

  @moduledoc "TBD"

  @callback infer(module, atom, arity) ::
    {:ok, Type.Function.t} |
    {:error, term} |
    :unknown
end

defmodule Type.NoInference do

  @moduledoc """
  A dummy inference module.
  """

  @behaviour Type.Inference.Api

  import Type, only: :macros

  @impl true
  @doc """
  Function which punts on inferring from MFA definitions.

  ```
  iex> Type.NoInference.infer(String, :split, 1)
  :unknown
  ```

  """
  def infer(_, _, _), do: :unknown

  @doc false
  def any_params(arity) do
    fn -> builtin(:any) end
    |> Stream.repeatedly
    |> Enum.take(arity)
  end
end
