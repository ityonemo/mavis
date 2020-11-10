defmodule Type.Function do

  @moduledoc """
  Represents a function type.

  There are two fields for the struct defined by this module.

  - `params` a list of types for the function arguments.  Note that the arity
    of the function is the length of this list.  May also be the atom `:any`
    which corresponds to "a function of any arity".
  - `return` the type of the returned value.

  ### Deviations from standard Erlang/Elixir:

  Mavis introduces a new type (that is not expressible via dialyzer).  This
  type should be referred to as `top-arity-n`.  All functions
  of arity/n are subtypes of said type.  It's represented with this form:

  `(_, _ -> any())` in the case of arity-2.  Note this is distinct
  from `(any(), any() -> any())`:  A member of `any-arity-2` is required
  to take any value without crashing.  This effectively functions as the
  bottom type for arity-2 functions.  A member of `top-arity-2` can have
  any requirements on the parameters.

  Concretely, the success type for the input of `&is_function(&1, n)`
  is `top-arity-n`.  Moreover, `(... -> any())` is the top type for all
  `top-arity` types.

  You may create top-arity functions with different return types, but
  you may not mix and match parameter types.

  ### Examples:

  - `(... -> integer())` would be represented as `%Type.Function{params: :any, return: %Type{name: :integer}}`
  - `(integer() -> integer())` would be represented as `%Type.Function{params: [%Type{name: :integer}], return: %Type{name: :integer}}`
  - `(_ -> integer())` is represented as `%Type.Function{params: 1, return: %Type{name: :integer}}`

  ### Shortcut Form

  The `Type` module lets you specify a function using "shortcut form" via the `Type.function/1` macro:

  ```
  iex> import Type
  iex> function((builtin(:atom) -> builtin(:pos_integer)))
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
  iex> import Type
  iex> Type.compare(function(( -> builtin(:atom))), function(( -> builtin(:integer))))
  :gt
  iex> Type.compare(function((builtin(:integer) -> builtin(:integer))),
  ...>              function((builtin(:atom) -> builtin(:integer))))
  :lt
  ```

  #### intersection

  Functions with distinct parameter types are nonoverlapping, even if their parameter
  types overlap.  If they have the same parameters, then their return values are intersected.

  ```elixir
  iex> import Type
  iex> Type.intersection(function(( -> 1..10)), function(( -> builtin(:integer))))
  %Type.Function{params: [], return: 1..10}
  iex> Type.intersection(function((builtin(:integer) -> builtin(:integer))),
  ...>                   function((1..10 -> builtin(:integer))))
  %Type{name: :none}
  ```

  functions with `:any` parameters intersected with a function with specified parameters
  will adopt the parameters of the intersected function.

  ```elixir
  iex> import Type
  iex> Type.intersection(function((... -> builtin(:pos_integer))),
  ...>                   function((1..10 -> builtin(:pos_integer))))
  %Type.Function{params: [1..10], return: %Type{name: :pos_integer}}
  ```

  #### union

  Functions are generally not merged in union operations, but if their parameters are
  identical then their return types will be merged.

  ```elixir
  iex> import Type
  iex> Type.union(function(( -> 1..10)), function(( -> 11..20)))
  %Type.Function{params: [], return: 1..20}
  ```

  #### subtype?

  A function type is the subtype of another if it has the same parameters and its return
  value type is the subtype of the other's

  ```elixir
  iex> import Type
  iex> Type.subtype?(function((builtin(:integer) -> 1..10)),
  ...>               function((builtin(:integer) -> builtin(:integer))))
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
  iex> import Type
  iex> Type.usable_as(function((builtin(:pos_integer) -> 1..10)), function((1..10 -> builtin(:pos_integer))))
  :ok
  iex> Type.usable_as(function((1..10 -> 1..10)), function((builtin(:pos_integer) -> builtin(:pos_integer))))
  {:maybe, [%Type.Message{type: %Type.Function{params: [1..10], return: 1..10},
                          target: %Type.Function{params: [%Type{name: :pos_integer}], return: %Type{name: :pos_integer}}}]}
  iex> Type.usable_as(function(( -> builtin(:atom))), function(( -> builtin(:pos_integer))))
  {:error, %Type.Message{type: %Type.Function{params: [], return: %Type{name: :atom}},
                         target: %Type.Function{params: [], return: %Type{name: :pos_integer}}}}
  ```
  """

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: :any, inferred: false]

  @type t :: %__MODULE__{
    params: [Type.t] | :any | arity,
    return: Type.t,
    inferred: boolean
  }

  import Type, only: [builtin: 1]

  defimpl Type.Properties do
    import Type, only: :macros

    use Type.Helpers

    group_compare do
      def group_compare(%{params: :any, return: r1}, %{params: :any, return: r2}) do
        Type.compare(r1, r2)
      end
      def group_compare(%{params: :any}, _),           do: :gt
      def group_compare(_, %{params: :any}),           do: :lt
      def group_compare(%{params: p1}, %{params: p2})
          when length(p1) < length(p2),                do: :gt
      def group_compare(%{params: p1}, %{params: p2})
          when length(p1) > length(p2),                do: :lt
      def group_compare(f1, f2) do
        [f1.return | f1.params]
        |> Enum.zip([f2.return | f2.params])
        |> Enum.each(fn {t1, t2} ->
          compare = Type.compare(t1, t2)
          unless compare == :eq do
            throw compare
          end
        end)
        :eq
      catch
        compare when compare in [:gt, :lt] -> compare
      end
    end

    alias Type.{Function, Message}

    usable_as do
      def usable_as(challenge = %{params: cparam}, target = %Function{params: tparam}, meta)
          when cparam == :any or tparam == :any do
        case Type.usable_as(challenge.return, target.return, meta) do
          :ok -> :ok
          # TODO: add meta-information here.
          {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
          {:error, _} -> {:error, Message.make(challenge, target, meta)}
        end
      end

      def usable_as(challenge = %{params: cparam}, target = %Function{params: tparam}, meta)
          when length(cparam) == length(tparam) do
        [challenge.return | tparam]           # note that the target parameters and the challenge
        |> Enum.zip([target.return | cparam]) # parameters are swapped here.  this is important!
        |> Enum.map(fn {c, t} -> Type.usable_as(c, t, meta) end)
        |> Enum.reduce(&Type.ternary_and/2)
        |> case do
          :ok -> :ok
          # TODO: add meta-information here.
          {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
          {:error, _} -> {:error, Message.make(challenge, target, meta)}
        end
      end
    end

    intersection do
      def intersection(%{params: :any, return: ret}, target = %Function{}) do
        new_ret = Type.intersection(ret, target.return)

        if new_ret == builtin(:none) do
          builtin(:none)
        else
          %Function{params: target.params, return: new_ret}
        end
      end
      def intersection(a, b = %Function{params: :any}) do
        intersection(b, a)
      end
      def intersection(%{params: p, return: lr}, %Function{params: p, return: rr}) do

        return = Type.intersection(lr, rr)

        if return == builtin(:none) do
          builtin(:none)
        else
          %Function{params: p, return: return}
        end
      end
    end

    subtype do
      def subtype?(challenge, target = %Function{params: :any}) do
        Type.subtype?(challenge.return, target.return)
      end
      def subtype?(challenge = %{params: p_c}, target = %Function{params: p_t})
          when p_c == p_t do
        Type.subtype?(challenge.return, target.return)
      end
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{params: :any, return: %Type{module: nil, name: :any}}, _), do: "function()"
    def inspect(%{params: :any, return: return}, opts) do
      concat(basic_inspect(:any, return, opts) ++ [")"])
    end
    def inspect(%{params: arity, return: return}, opts) when is_integer(arity) do
      arity
      |> basic_inspect(return, opts)
      |> Kernel.++([")"])
      |> concat
    end
    def inspect(%{params: params, return: return}, opts) do

      # check if any of the params or the returns have *when* statements
      # TODO: nested variables

      [return | params]
      |> Enum.filter(fn
        %Type.Function.Var{} -> true
        _ -> false
      end)
      |> case do
        [] -> basic_inspect(params, return, opts)
        free_vars ->
          when_list = free_vars
          |> Enum.uniq
          |> Enum.map(&Inspect.inspect(&1, opts))
          |> Enum.intersperse(", ")

          basic_inspect(params, return, opts) ++ [" when " | when_list]
      end
      |> Kernel.++([")"])
      |> concat
    end

    defp basic_inspect(params, return, opts) do
      ["(", render_params(params, opts), " -> ", to_doc(return, opts)]
    end

    defp render_params(:any, _), do: "..."
    defp render_params(arity, _) when is_integer(arity) do
      "_"
      |> List.duplicate(arity)
      |> Enum.intersperse(", ")
      |> concat
    end
    defp render_params(lst, opts) do
      lst
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(", ")
      |> concat
    end
  end
end
