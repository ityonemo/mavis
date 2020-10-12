defmodule Type.Function do

  @moduledoc """
  represents a function type.
  """

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: [], inferred: true]

  @type t :: %__MODULE__{
    params: [Type.t] | :any,
    return: Type.t,
    inferred: true
  }

  import Type, only: [builtin: 1]

  # inference code.  Mavis can performs type inference on function code.  The generalized
  # bits of that are going to live here.

  @info_parts [:module, :name, :arity, :env]
  def infer(fun) do
    [module, name, arity, _env] = fun
    |> :erlang.fun_info
    |> Keyword.take(@info_parts)
    |> Keyword.values()

    case :code.get_object_code(module) do
      {^module, binary, _filepath} ->
        {:beam_file, ^module, _funs_list, _vsn, _meta, functions} = :beam_disasm.file(binary)
        code = Enum.find_value(functions,
          fn
            {:function, ^name, ^arity, _, code} -> code
            _ -> false
          end)

        code || raise "fatal error; can't find function `#{name}/#{arity}` in module #{inspect module}"

        Type.Inference.run(code, starting_map(arity))
      :error ->
        {:ok, %__MODULE__{params: any_for(arity), return: builtin(:any), inferred: false}}
    end
  end

  defp any_for(arity) do
    fn -> builtin(:any) end
    |> Stream.repeatedly
    |> Enum.take(arity)
  end

  defp starting_map(0), do: %{}
  defp starting_map(arity) do
    0..(arity - 1)
    |> Enum.map(&{&1, builtin(:any)})
    |> Enum.into(%{})
  end

  def asm(fun) do
    [module, name, arity, _env] = fun
    |> :erlang.fun_info
    |> Keyword.take(@info_parts)
    |> Keyword.values()

    case :code.get_object_code(module) do
      {^module, binary, _filepath} ->
        {:beam_file, ^module, _funs_list, _vsn, _meta, functions} = :beam_disasm.file(binary)
        code = Enum.find_value(functions,
          fn
            {:function, ^name, ^arity, _, code} -> code
            _ -> false
          end)

        code || raise "fatal error; can't find function `#{name}/#{arity}` in module #{inspect module}"
      :error ->
        raise "nope"
    end
  end

  def has_opcode?({m, f, a}, desired_opcode) do
    with {^m, binary, _filepath} <- :code.get_object_code(m),
         {:beam_file, ^m, _funs_list, _vsn, _meta, functions} <- :beam_disasm.file(binary) do
      code = Enum.find_value(functions,
        fn
          {:function, ^f, ^a, _, code} -> code
          _ -> false
        end)

      unless code do
        raise "function #{inspect m}.#{f}/#{a} not found."
      end

      Enum.any?(code, fn
        opcode when is_tuple(opcode) ->
          opcode
          |> Tuple.to_list
          |> Enum.zip(desired_opcode)
          |> Enum.all?(fn {a, b} -> a == b end)
        _ -> false
      end)
    else
      _ -> raise "function #{inspect m}.#{f}/#{a} not found."
    end
  end

  defimpl Type.Properties do
    import Type, only: :macros

    use Type

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
      def intersection(%{params: lp, return: lr}, %Function{params: rp, return: rr})
          when length(lp) == length(rp) do

        types = [lr | lp]
        |> Enum.zip([rr | rp])
        |> Enum.map(fn {l, r} -> Type.intersection(l, r) end)

        if Enum.any?(types, &(&1 == builtin(:none))) do
          builtin(:none)
        else
          %Function{params: tl(types), return: hd(types)}
        end
      end
    end

    def subtype?(fn_type, fn_type), do: true
    def subtype?(_fn_type, builtin(:any)), do: true
    def subtype?(challenge, target = %Function{params: :any}) do
      Type.subtype?(challenge.return, target.return)
    end
    def subtype?(challenge = %{params: p_c}, target = %Function{params: p_t})
        when p_c == p_t do
      Type.subtype?(challenge.return, target.return)
    end
    def subtype?(_, _), do: false
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{params: :any, return: %Type{module: nil, name: :any}}, _), do: "function()"
    def inspect(%{params: params, return: return}, opts) do
      concat(["(", render_params(params, opts),
              " -> ", to_doc(return, opts), ")"])
    end

    defp render_params(:any, _), do: "..."
    defp render_params(lst, opts) do
      lst
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(", ")
      |> concat
    end
  end
end
