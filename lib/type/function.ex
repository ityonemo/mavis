defmodule Type.Function do

  @moduledoc """
  represents a function type.  Note that coercion of a function type
  operates in the *opposite* direction as
  """

  @enforce_keys [:return]
  defstruct @enforce_keys ++ [params: []]

  @type t :: %__MODULE__{
    params: [Type.t] | :any,
    return: Type.t
  }

#  def from_spec({:"::", _, [header, return]}, context) do
#    {name, _, params} = header
#    {name, %__MODULE__{
#      params: Enum.map(params, &Type.of(&1, context)),
#      return: Type.of(return, context)
#    }}
#  end

  defimpl Type.Properties do
    import Type, only: :macros

    use Type.Impl

    def group_order(%{params: :any, return: r1}, %{params: :any, return: r2}) do
      Type.order(r1, r2)
    end
    def group_order(%{params: :any}, _), do: true
    def group_order(_, %{params: :any}), do: false
    def group_order(%{params: p1}, %{params: p2})
        when length(p1) < length(p2), do: true
    def group_order(%{params: p1}, %{params: p2})
        when length(p1) > length(p2), do: false
    def group_order(f1, f2) do
      [f1.return | f1.params]
      |> Enum.zip([f2.return | f2.params])
      |> Enum.any?(fn {t1, t2} ->
        # they can't be equal
        Type.order(t1, t2) and not Type.order(t2, t1)
      end)
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
end
