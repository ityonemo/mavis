defmodule Type.Opaque do
  @moduledoc """
  A wrapper for opaqueness.
  """

  @enforce_keys [:module, :name, :params, :type]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
    module: module,
    name: atom,
    params: [Type.t],
    type: Type.t
  }

  import Type, only: :macros

  #defimpl Type.Algebra do
  #  import Type, only: :macros
#
  #  import Type.Helpers
  #  alias Type.{Message, Opaque}
#
  #  def compare(left = %{type: this}, right = %Opaque{type: this}) do
  #    left_arity = length(left.params)
  #    right_arity = length(right.params)
  #    cond do
  #      left.module > right.module -> :gt
  #      left.module < right.module -> :lt
  #      left.name   > right.name -> :gt
  #      left.name   < right.name -> :lt
  #      left_arity  > right_arity -> :gt
  #      left_arity  < right_arity -> :lt
  #      true ->
  #        left.params
  #        |> Enum.zip(right.params)
  #        |> find_cmp
  #        |> Kernel.||(:eq)
  #    end
  #  end
#
  #  def compare(this, other) do
  #    case Type.compare(this.type, other) do
  #      :eq -> :lt
  #      cmp -> cmp
  #    end
  #  end
#
  #  defp find_cmp(leftrightlist) do
  #    Enum.find_value(leftrightlist, fn {l, r} ->
  #      if cmp = Type.compare(l, r) != :eq, do: cmp
  #    end)
  #  end
#
  #  def typegroup(%{type: opaque}) do
  #    Type.Algebra.typegroup(opaque)
  #  end
#
  #  usable_as do
  #    def usable_as(challenge = %Opaque{}, target, meta) do
  #      case Type.usable_as(challenge.type, target, meta) do
  #        :ok ->
  #          # TODO: add opaqueness message here.
  #          {:maybe, [Message.make(challenge, target, meta)]}
  #        any -> any
  #      end
  #    end
  #  end
#
  #  intersection do
  #    def intersection(%Opaque{}, _non_opaque) do
  #      none()
  #    end
  #  end
#
  #  subtype do
  #  end
#
  #  def normalize(type), do: type
  #end

  defimpl Inspect do
    import Inspect.Algebra
    def inspect(opaque, opts) do
      params = opaque.params
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(", ")

      concat(["#{inspect opaque.module}.#{opaque.name}("] ++ params ++ [")"])
    end
  end
end
