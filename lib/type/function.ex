defmodule Type.Function do

  @moduledoc """
  Represents a function type.

  There are two fields for the struct defined by this module.

  - `params` a list of types for the function arguments.  Note that the arity
    of the function is the length of this list.  May also be the atom `:any`
    which corresponds to "a function of any arity".
  - `return` the type of the returned value.

  ### Examples:

  - `(... -> integer())` would be represented as `%Type.Function{params: :any, return: %Type{name: :integer}}`
  - `(integer() -> integer())` would be represented as `%Type.Function{params: [%Type{name: :integer}], return: %Type{name: :integer}}`

  ### Shortcut Form

  The `Type` module lets you specify a function using "shortcut form" via the `Type.function/1` macro:

  ```
  iex> import Type, only: :macros
  iex> function((atom() -> pos_integer()))
  %Type.Function{params: [%Type{name: :atom}], return: %Type{name: :pos_integer}}
  ```

  ### Inference

  By default, Mavis will not attempt to perform inference on function types.

  ```elixir
  iex> inspect Type.of(&(&1 + 1))
  "(any() -> any())"
  ```

  If you would like to perform inference on the function to obtain
  more details on the acceptable function types, set the inference
  environment variable.  For example, if you're using the `:mavis_inference` hex package, do:

  ```
  Application.put_env(:mavis, :inference, Type.Inference)
  ```

  The default module for this is `Type.NoInference`

  ### Key functions:

  #### comparison

  Functions are ordered first by the type order on their return type,
  followed by type order on their parameters.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.compare(function(( -> atom())), function(( -> integer())))
  :gt
  iex> Type.compare(function((integer() -> integer())),
  ...>              function((atom() -> integer())))
  :lt
  ```

  #### intersection

  Functions with distinct parameter types are nonoverlapping, even if their parameter
  types overlap.  If they have the same parameters, then their return values are intersected.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersection(function(( -> 1..10)), function(( -> integer())))
  %Type.Function{params: [], return: 1..10}
  iex> Type.intersection(function((integer() -> integer())),
  ...>                   function((1..10 -> integer())))
  %Type{name: :none}
  ```

  functions with `:any` parameters intersected with a function with specified parameters
  will adopt the parameters of the intersected function.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersection(function((... -> pos_integer())),
  ...>                   function((1..10 -> pos_integer())))
  %Type.Function{params: [1..10], return: %Type{name: :pos_integer}}
  ```

  #### union

  Functions are generally not merged in union operations, but if their parameters are
  identical then their return types will be merged.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.union(function(( -> 1..10)), function(( -> 11..20)))
  %Type.Function{params: [], return: 1..20}
  ```

  #### subtype?

  A function type is the subtype of another if it has the same parameters and its return
  value type is the subtype of the other's

  ```elixir
  iex> import Type, only: :macros
  iex> Type.subtype?(function((integer() -> 1..10)),
  ...>               function((integer() -> integer())))
  true
  ```

  #### usable_as

  The `usable_as` relationship for functions may not necessarily be obvious.  An
  easy way to think about it, is:  if I passed a function with this type to a
  function that demanded the other type how confident would I be that it would
  not crash.

  A function is `usable_as` another function if all of its parameters are
  supertypes of the targeted function; and if its return type is subtypes of the
  return type of the targeted function.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.usable_as(function((pos_integer() -> 1..10)), function((1..10 -> pos_integer())))
  :ok
  iex> Type.usable_as(function((1..10 -> 1..10)), function((pos_integer() -> pos_integer())))
  {:maybe, [%Type.Message{type: %Type.Function{params: [1..10], return: 1..10},
                          target: %Type.Function{params: [%Type{name: :pos_integer}], return: %Type{name: :pos_integer}}}]}
  iex> Type.usable_as(function(( -> atom())), function(( -> pos_integer())))
  {:error, %Type.Message{type: %Type.Function{params: [], return: %Type{name: :atom}},
                         target: %Type.Function{params: [], return: %Type{name: :pos_integer}}}}
  ```
  """

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: :any]

  @type t :: %__MODULE__{
    params: [Type.t] | :any | pos_integer,
    return: Type.t
  }

  @type return :: {:ok, Type.t} | {:maybe, Type.t, [Type.Message.t]} | {:error, Type.Message.t}

  @spec apply_types(t | Type.Union.t(t), [Type.t], keyword) :: return
  @doc """
  applies types to a function definition.

  Raises with `Type.FunctionError` if one of the following is true:
  - an :any function is attempted to be applied
  - a `top-arity` function is attempted to be applied
  - a non-function (or union of functions) is attempted to be applied

  Returns
  - `{:ok, return_type}` when the function call is successful.
  - `{:maybe, return_type, [messages]}` when one or more of the parameters
    is overspecified.
  - `{:error, message}` when any of the parameters is disjoint

  Examples:

  ```
  iex> import Type, only: :macros
  iex> func = function ((pos_integer() -> float()))
  iex> Type.Function.apply_types(func, [pos_integer()])
  {:ok, %Type{name: :float}}
  iex> Type.Function.apply_types(func, [non_neg_integer()])
  {:maybe, %Type{name: :float}, [
    %Type.Message{
      type: %Type.Union{of: [%Type{name: :pos_integer}, 0]},
      target: %Type{name: :pos_integer},
      meta: [message: "non_neg_integer() is overbroad for argument 1 (pos_integer()) of function (pos_integer() -> float())"]
    }]}
  iex> Type.Function.apply_types(func, [float()])
  {:error,
    %Type.Message{
      type: %Type{name: :float},
      target: %Type{name: :pos_integer},
      meta: [message: "float() is disjoint to argument 1 (pos_integer()) of function (pos_integer() -> float())"]
    }}
  iex> var_func = function((i -> i when i: integer()))
  iex> Type.Function.apply_types(var_func, [1..10])
  {:ok, 1..10}
  ```
  """
  def apply_types(fun, vars, meta \\ [])
  def apply_types(fun = %__MODULE__{params: plst}, vlst, meta) when
    length(plst) == length(vlst) do

    var_match = match_vars(plst, vlst)

    vlst
    |> Enum.zip(plst)
    |> Enum.with_index(1)
    |> Enum.map(fn {{v, p}, idx} ->
      arg = argument(fun, idx - 1)
      Type.usable_as(v, p, meta)
      |> add_message(v, idx, arg, fun)
    end)
    |> Enum.reduce({:ok, fun.return}, &apply_reduce/2)
    |> substitute_vars(var_match)
  end
  def apply_types(fun = %__MODULE__{params: arity}, params, _) when length(params) == arity do
    {:ok, fun.return}
  end
  def apply_types(union = %Type.Union{of: funs}, vars, meta) do
    # double check that everything is okay.
    segregated_vars = funs
    |> Enum.reduce(Enum.map(vars, &[&1]), fn
      %__MODULE__{params: p}, acc when length(p) == length(vars) ->
        p
        |> Enum.zip(acc)
        |> Enum.map(fn {a, b} -> [a | b] end)
      type, _ ->
        varp = length(vars)
        raise Type.FunctionError, "type #{inspect type} in union #{inspect union} is not a function with #{varp} parameter#{p varp}"
    end)
    |> Enum.map(&Enum.reverse/1)

    # partition the variables based on how they work with the
    evaluated_type = segregated_vars
    |> Enum.map(fn [var | segments] ->
      Type.partition(var, segments)
    end)
    |> transpose
    |> Enum.zip(funs)
    |> Enum.map(fn {part, fun} -> apply_types(fun, part) end)
    |> Enum.flat_map(fn
      # throw away most of this information.  We figure out whether it's okay by checking
      # out the preimage map.
      {:ok, type} -> [type]
      {:error, _} -> []
      # this should be unreachable because by definition everything should be proper
      # subtypes.
      {:maybe, _, _} -> raise "unreachable"
    end)
    |> Type.union()

    import Type, only: :macros

    if evaluated_type == none() do
      # find the type that doesn't match.  Sorry, just going to do the worst
      # possible thing here.
      vars
      |> Enum.with_index(1)
      |> Enum.map(fn {var, idx} ->
        arg = argument(union, idx - 1)
        var
        |> Type.usable_as(arg, meta)
        |> add_message(var, idx, arg, union)
      end)
      |> Enum.reduce(&Type.ternary_and/2)
    else
      segregated_vars
      |> Enum.with_index(1)
      |> Enum.map(fn {[var | segments], idx} ->
        if Type.covered?(var, segments) do
          :ok
        else
          arg = argument(union, idx - 1)
          add_message({:maybe, [Type.Message.make(var, arg, meta)]},
            var, idx, arg, union)
        end
      end)
      |> Enum.reduce({:ok, evaluated_type}, &apply_reduce/2)
    end
  end

  ## error raising
  def apply_types(%__MODULE__{params: :any}, _, _) do
    raise Type.FunctionError, "cannot apply a function with ... parameters"
  end
  def apply_types(fun = %__MODULE__{params: params}, vars, _) do
    funp = if is_integer(params), do: params, else: length(fun.params)
    varp = length(vars)
    raise Type.FunctionError, "mismatched arity; #{inspect fun} expects #{funp} parameter#{p funp}, got #{varp} parameter#{p varp} #{inspect vars}"
  end
  def apply_types(any, _, _) do
    raise Type.FunctionError, "cannot apply a function to the type #{inspect any}"
  end

  @spec apply_reduce(Type.ternary, return) :: return
  defp apply_reduce(:ok,             {:ok, term}),           do: {:ok, term}
  defp apply_reduce({:maybe, msgs},  {:ok, term}),           do: {:maybe, term, msgs}
  defp apply_reduce({:error, msg},   {:ok, _}),              do: {:error, msg}
  defp apply_reduce(:ok,             {:maybe, term, msgs}),  do: {:maybe, term, msgs}
  defp apply_reduce({:maybe, msgs1}, {:maybe, term, msgs2}), do: {:maybe, term, msgs1 + msgs2}
  defp apply_reduce({:error, msg},   {:maybe, _, _}),        do: {:error, msg}
  defp apply_reduce(_,               {:error, msg}),         do: {:error, msg}

  defp match_vars(plist, vlist) do
  #  plist
  #  |> Enum.zip(vlist)
  #  |> Enum.filter(&match?({%Type.Function.Var{}, _}, &1))
  #  |> Enum.into(%{})
  end

  defp substitute_vars({:ok, result}, match) do
#    {:ok, Type.Function.Var.resolve(result, match)}
  end
  defp substitute_vars({:maybe, result, msg}, match) do
#    {:maybe, Type.Function.Var.resolve(result, match), msg}
  end
  defp substitute_vars(error, _), do: error

  # pluralization
  defp p(1), do: ""
  defp p(_), do: "s"

  defp add_message(:ok, _, _, _, _), do: :ok
  defp add_message({:maybe, [message]}, var, idx, arg, fun) do
    {:maybe, [%{message | meta: message.meta ++
      [message: "#{inspect var} is overbroad for argument #{idx} (#{inspect arg}) of function #{inspect fun}"]}]}
  end
  defp add_message({:error, message}, var, idx, arg, fun) do
    {:error, %{message | meta: message.meta ++
      [message: "#{inspect var} is disjoint to argument #{idx} (#{inspect arg}) of function #{inspect fun}"]}}
  end

  # NB: This is zero-indexed.
  defp argument(%__MODULE__{params: params}, index) do
    Enum.at(params, index)
  end
  defp argument(%Type.Union{of: funs}, index) do
    funs
    |> Enum.map(&argument(&1, index))
    |> Enum.into(%Type.Union{})
  end

  @spec transpose([[Type.t]]) :: [[Type.t]]
  defp transpose(lst) do
    lst
    |> Enum.reduce(List.duplicate([], length(hd(lst))),
      fn vec, acc ->
        vec
        |> Enum.zip(acc)
        |> Enum.map(fn {a, b} -> [a | b] end)
      end)
    |> Enum.map(&Enum.reverse/1)
  end

  #defimpl Type.Algebra do
  #  import Type, only: :macros
#
  #  use Type.Helpers
#
  #  group_compare do
  #    def group_compare(%{params: :any, return: r1}, %{params: :any, return: r2}) do
  #      Type.compare(r1, r2)
  #    end
  #    def group_compare(%{params: :any}, _),           do: :gt
  #    def group_compare(_, %{params: :any}),           do: :lt
  #    def group_compare(%{params: p1}, %{params: p2})
  #        when length(p1) < length(p2),                do: :gt
  #    def group_compare(%{params: p1}, %{params: p2})
  #        when length(p1) > length(p2),                do: :lt
  #    def group_compare(f1, f2) do
  #      [f1.return | f1.params]
  #      |> Enum.zip([f2.return | f2.params])
  #      |> Enum.each(fn {t1, t2} ->
  #        compare = Type.compare(t1, t2)
  #        unless compare == :eq do
  #          throw compare
  #        end
  #      end)
  #      :eq
  #    catch
  #      compare when compare in [:gt, :lt] -> compare
  #    end
  #  end
#
  #  alias Type.{Function, Message}
#
  #  usable_as do
  #    def usable_as(challenge = %{params: cparam}, target = %Function{params: tparam}, meta)
  #        when cparam == :any or tparam == :any do
  #      case Type.usable_as(challenge.return, target.return, meta) do
  #        :ok -> :ok
  #        # TODO: add meta-information here.
  #        {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
  #        {:error, _} -> {:error, Message.make(challenge, target, meta)}
  #      end
  #    end
#
  #    def usable_as(challenge = %{params: cparam}, target = %Function{params: tparam}, meta)
  #        when length(cparam) == length(tparam) do
  #      [challenge.return | tparam]           # note that the target parameters and the challenge
  #      |> Enum.zip([target.return | cparam]) # parameters are swapped here.  this is important!
  #      |> Enum.map(fn {c, t} -> Type.usable_as(c, t, meta) end)
  #      |> Enum.reduce(&Type.ternary_and/2)
  #      |> case do
  #        :ok -> :ok
  #        # TODO: add meta-information here.
  #        {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
  #        {:error, _} -> {:error, Message.make(challenge, target, meta)}
  #      end
  #    end
  #  end
#
  #  intersection do
  #    def intersection(%{params: :any, return: ret}, target = %Function{}) do
  #      new_ret = Type.intersection(ret, target.return)
#
  #      if new_ret == none() do
  #        none()
  #      else
  #        %Function{params: target.params, return: new_ret}
  #      end
  #    end
  #    def intersection(a, b = %Function{params: :any}) do
  #      intersection(b, a)
  #    end
  #    def intersection(lf = %Function{params: i}, rf = %Function{params: rp})
  #        when length(rp) == i do
#
  #      case Type.intersection(lf.return, rf.return) do
  #        none() -> none()
  #        return -> %Function{params: rp, return: return}
  #      end
  #    end
  #    def intersection(%{params: p, return: lr}, %Function{params: p, return: rr}) do
  #      case Type.intersection(lr, rr) do
  #        none() -> none()
  #        return ->
  #          %Function{params: p, return: return}
  #      end
  #    end
  #  end
#
  #  subtype do
  #    def subtype?(challenge, target = %Function{params: :any}) do
  #      Type.subtype?(challenge.return, target.return)
  #    end
  #    def subtype?(challenge = %{params: p_c}, target = %Function{params: p_t})
  #        when p_c == p_t do
  #      Type.subtype?(challenge.return, target.return)
  #    end
  #  end
#
  #  subtract do
  #    def subtract(%{params: p, return: r1}, %Function{params: p, return: r2}) do
  #      case Type.subtract(r1, r2) do
  #        none() -> none()
  #        %Type.Subtraction{base: b, exclude: e} ->
  #          %Type.Subtraction{
  #            base: %Function{params: p, return: b},
  #            exclude: %Function{params: p, return: e}}
  #        type ->
  #          %Function{params: p, return: type}
  #      end
  #    end
  #    def subtract(lf = %{params: p}, rf = %Function{params: l}) when length(p) == l do
  #      case Type.subtract(lf.return, rf.return) do
  #        none() -> none()
  #        %Type.Subtraction{base: b, exclude: e} ->
  #          %Type.Subtraction{
  #            base: %Function{params: p, return: b},
  #            exclude: %Function{params: p, return: e}}
  #        type ->
  #          %Function{params: p, return: type}
  #      end
  #    end
  #  end
#
  #  def normalize(function = %{params: i}) when is_integer(i) do
  #    %Function{
  #      params: List.duplicate(any(), i),
  #      return: Type.normalize(function.return)
  #    }
  #  end
  #  def normalize(function = %{params: list}) when is_list(list) do
  #    %Function{
  #      params: Enum.map(list, &Type.normalize/1),
  #      return: Type.normalize(function.return)
  #    }
  #  end
  #  def normalize(function = %{params: :any}) do
  #    %{function | return: Type.normalize(function.return)}
  #  end
  #end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{params: :any, return: return}, opts) do
      concat(["type((... -> ", to_doc(return, opts), "))"])
    end

    def inspect(%{params: params, return: return}, opts) when is_list(params) do
      params_docs = params
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(", ")

      concat(["type(("] ++ params_docs ++ [" -> ", to_doc(return, opts), "))"])
    end

#    def inspect(%{params: :any, return: %Type{module: nil, name: :any}}, _), do: "function()"
#    def inspect(%{params: :any, return: return}, opts) do
#      concat(basic_inspect(:any, return, opts) ++ [")"])
#    end
#    def inspect(%{params: arity, return: return}, opts) when is_integer(arity) do
#      concat(basic_inspect(arity, return, opts) ++ [")"])
#    end
#    def inspect(%{params: params, return: return}, opts) do
#
#      # check if any of the params or the returns have *when* statements
#      # TODO: nested variables
#
#      [return | params]
#      |> Enum.filter(&match?(%Type.Function.Var{}, &1))
#      |> case do
#        [] -> basic_inspect(params, return, opts)
#        free_vars ->
#          when_list = free_vars
#          |> Enum.uniq
#          |> Enum.map(&Inspect.inspect(&1, %{opts | custom_options: [show_constraints: true]}))
#          |> Enum.intersperse(", ")
#
#          basic_inspect(params, return, opts) ++ [" when " | when_list]
#      end
#      |> Kernel.++([")"])
#      |> concat
#    end
#
#    defp basic_inspect(params, return, opts) do
#      ["(", render_params(params, opts), " -> ", to_doc(return, opts)]
#    end
#
#    defp render_params(:any, _), do: "..."
#    defp render_params(arity, _) when is_integer(arity) do
#      "_"
#      |> List.duplicate(arity)
#      |> Enum.intersperse(", ")
#      |> concat
#    end
#    defp render_params(lst, opts) do
#      lst
#      |> Enum.map(&to_doc(&1, opts))
#      |> Enum.intersperse(", ")
#      |> concat
#    end
  end
end

defmodule Type.FunctionError do
  defexception [:message]
end
