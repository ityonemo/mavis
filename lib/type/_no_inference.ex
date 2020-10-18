defmodule Type.Inference.Api do
  @callback infer(function | mfa) :: Type.Function.t
end

defmodule Type.NoInference do

  @behaviour Type.Inference.Api

  import Type, only: :macros

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
end
