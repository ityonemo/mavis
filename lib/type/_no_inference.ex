defmodule Type.Inference.Api do

  @moduledoc "TBD"

  @callback infer(function | mfa) ::
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
  Function which assumes that any lambda passed to it takes any parameters and
  outputs any.  Punts on inferring from MFA definitions.

  ```
  iex> inspect Type.NoInference.infer(&(&1 + 1))
  "{:ok, (any() -> any())}"

  iex> inspect Type.NoInference.infer(&(&1 + &2))
  "{:ok, (any(), any() -> any())}"

  iex> Type.NoInference.infer({String, :split, 1})
  :unknown
  ```

  """
  def infer(fun) when is_function(fun) do
    arity = fun
    |> Function.info()
    |> Keyword.get(:arity)

    params = fn -> builtin(:any) end
    |> Stream.repeatedly
    |> Enum.take(arity)

    {:ok, %Type.Function{
      params: params,
      return: builtin(:any),
      inferred: false
    }}
  end
  def infer({_, _, _}), do: :unknown
end
