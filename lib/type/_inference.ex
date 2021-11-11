defmodule Type.Inference.Api do

  @moduledoc "TBD"

  @callback infer(module, atom, arity) ::
    {:ok, Type.inferred} |
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
  {:ok, %Type.Function{branches: [%Type.Function.Branch{params: [%Type{name: :any}],
                       return: %Type{name: :any}}]}}
  ```

  """
  def infer(_, _, arity) do
    {:ok, type((List.duplicate(any(), arity) -> any()))}
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
  def infer(module, fun, arity) do
    with {:module, _} <- Code.ensure_loaded(module),
         {:ok, specs} <- Code.Typespec.fetch_specs(module),
         spec when spec != nil <- find_spec(module, specs, fun, arity) do
      {:ok, spec}
    else
     :error ->
      # for some types, which are coming from modules which aren't
      # loaded from disk (e.g. .exs modules) fetch_specs won't work,
      # so we need to punt to a different method.
      :unknown
     nil ->
       # note that we might be trying to find information for
       # a lambda, which won't necessarily be directly exported.
       :unknown
     error -> error
    end
  end

  defp find_spec(module, specs, fun, arity) do
    Enum.find_value(specs, fn
      {{^fun, ^arity}, specs_for_mfa} ->
        specs_for_mfa
        |> Enum.map(&Type.Spec.parse(&1, %{"$mfa": {module, fun, arity}}))
        |> Type.union
      _ -> false
    end)
  end
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
