defmodule Type.Inference.Api do

  @moduledoc "TBD"

  @callback infer(module, atom, arity) ::
    {:ok, Type.Function.t} |
    {:error, term} |
    :unknown
end

defmodule Type.NoInference do
  @moduledoc """
  A fallback inference module.  Builds a type out of the arity
  of the function, claiming that it takes `t:any/0` values for
  all of the parameters and returns `t:any/0`
  """

  @behaviour Type.Inference.Api

  import Type, only: :macros

  @impl true
  @doc """
  Function which punts on inferring from MFA definitions.

  ```
  iex> Type.NoInference.infer(String, :split, 1)
  {:ok, %Type.Function{params: [%Type{name: :any}],
                       return: %Type{name: :any}}}
  ```

  """
  def infer(_, _, arity) do
    {:ok, %Type.Function{params: any_params(arity),
                         return: builtin(:any)}}
  end

  @doc false
  def any_params(arity) do
    fn -> builtin(:any) end
    |> Stream.repeatedly
    |> Enum.take(arity)
  end
end

defmodule Type.SpecInference do
  @moduledoc """
  An inference module which looks up the spec of the function
  and if it can find it, it reports that as its associated type.
  """

  @behaviour Type.Inference.Api

  @impl true
  @doc """
  ### Example

  ```
  iex> Type.SpecInference.infer(String, :trim, 1)
  %Type.Function{params: [%Type{module: String, name: :t}],
                 return: %Type{module: String, name: :t}}
  ```

  """
  defdelegate infer(module, fun, arity), to: Type, as: :fetch_spec
end

defmodule Type.Inference.Pipeline do
  @moduledoc """
  composes inference modules into a single inference pipeline.
  """

  @doc """
  creates a new inference modules out others.  Order is important,
  subsequent modules should be considered to be fallbacks to previous
  ones.  For example, you might want to put caches in the front,
  followed by user overrides, followed by type-spec derived inferences,
  followed by computed inference.

  ### usage:

  First, define the pipeline.
  ```
  defpipeline PipelineModule, [Inference1, Inference2, Inference3]
  ```

  then you may use it as expected:
  ```
  PipelineModule.infer(String, :trim, 1)
  ```
  """
  @spec defpipeline(module, [module]) :: Macro.t
  defmacro defpipeline(name, pipeline) do
    quote do
      defmodule unquote(name) do
        @behaviour Type.Inference.Api

        @impl true
        def infer(module, fun, arity) do
          Enum.reduce(unquote(pipeline), :unknown, fn
            target, :unknown ->
              target.infer(module, fun, arity)
            target, result -> result
          end)
        end
      end
    end
  end
end
