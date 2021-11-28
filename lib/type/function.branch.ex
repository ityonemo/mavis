defmodule Type.Function.Branch do
  use Type.Helpers

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: :any]

  @type t :: %__MODULE__{
    params: [Type.t] | :any | pos_integer,
    return: Type.t
  }

  @none %Type{name: :none}

  alias Type.Function

  def compare(_, %Function{}), do: raise "branches and functions are incomparable"

  def compare(%{params: lparams, return: lreturn}, %__MODULE__{params: rparams, return: rreturn})
      when lreturn != rreturn do

    case {length_(lparams), length_(rparams)} do
      # note that functions with more parameters are "less than" functions with less parameters.
      {ll, rl} when ll > rl -> :lt
      {ll, rl} when ll < rl -> :gt
      _ ->
        # note that
        Type.compare(lreturn, rreturn)
    end
  end

  def compare(%{params: lparams}, %__MODULE__{params: rparams}) do
    case {length_(lparams), length_(rparams)} do
      {ll, rl} when ll > rl -> :lt
      {ll, rl} when ll < rl -> :gt
      _ ->
        lparams
        |> sub_none
        |> Enum.zip(sub_none(rparams))
        |> Enum.reduce_while([], fn
          {same, same}, [] -> {:cont, []}
          {left, right}, [] -> {:halt, Type.compare(right, left)}
        end)
    end
  end

  @spec length_(:any | integer | [Type.t]) :: non_neg_integer() | :any
  defp length_(:any), do: :any
  defp length_(top_arity) when is_integer(top_arity), do: top_arity
  defp length_(list), do: length(list)

  @spec sub_none(integer | [Type.t]) :: [Type.t]
  defp sub_none(top_arity) when is_integer(top_arity) do
    List.duplicate(@none, top_arity)
  end
  defp sub_none(list), do: list

  def intersect(_, %Function{}), do: raise "branches and functions are incompatible"
  def intersect(%{params: lparams, return: lreturn}, %__MODULE__{params: rparams, return: rreturn}) do
    import Type, only: :macros
    case Type.intersect(lreturn, rreturn) do
      none() -> none()
      return ->
        %__MODULE__{params: params_intersect(lparams, rparams), return: return}
    end
  catch
    :none -> %Type{name: :none}
  end
  def intersect(_, _), do: %Type{name: :none}

  @spec params_intersect([Type.t], [Type.t]) :: [Type.t]
  defp params_intersect(lparams, rparams) do
    case {length_(lparams), length_(rparams)} do
      {:any, _} -> rparams
      {_, :any} -> lparams
      {ll, rl} when ll != rl -> throw :none
      # TODO: one of these is redundant.
      _ when is_integer(rparams) -> lparams
      _ when is_integer(lparams) -> rparams
      _ ->
        lparams
        |> Enum.zip(rparams)
        |> Enum.map(fn {a, b} -> Type.union(a, b) end)
    end
  end

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
