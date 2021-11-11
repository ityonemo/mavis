defmodule Type.Function.Branch do
  use Type.Helpers

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: :any]

  @type t :: %__MODULE__{
    params: [Type.t] | :any | pos_integer,
    return: Type.t
  }

  defimpl Inspect do
    import Inspect.Algebra
    import Type, only: :macros

    def inspect(%{params: :any, return: any()}, _opts) do
      "function()"
    end
    def inspect(%{params: :any, return: return}, opts) do
      concat_with_type(["(... -> ", to_doc(return, strip(opts)), ")"], opts)
    end

    def inspect(%{params: params, return: return}, opts) when is_list(params) do
      params_docs = params
      |> Enum.map(&to_doc(&1, strip(opts)))
      |> Enum.intersperse(", ")

      concat_with_type(["("] ++ params_docs ++ [" -> ", to_doc(return, strip(opts)), ")"], opts)
    end

    def inspect(%{params: count, return: return}, opts) when is_integer(count) do
      params_docs = "_"
      |> List.duplicate(count)
      |> Enum.intersperse(", ")

      concat_with_type(["("] ++ params_docs ++ [" -> ", to_doc(return, strip(opts)), ")"], opts)
    end

    defp concat_with_type(doc, opts) do
      if opts.custom_options[:no_type] do
        concat(doc)
      else
        concat(["type("] ++ doc ++ [")"])
      end
    end

    defp strip(opts) do
      %{opts | custom_options: Keyword.delete(opts.custom_options, :no_type)}
    end
  end
end
