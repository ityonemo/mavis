defmodule Type.Function.Var do
  import Type, only: :macros
  @enforce_keys [:name]
  defstruct @enforce_keys ++ [constraint: builtin(:any)]
end

defimpl Inspect, for: Type.Function.Var do
  def inspect(var, _opts) do
    "#{var.name}"
  end
end

defimpl Type.Properties, for: Type.Function.Var do

  alias Type.Function.Var

  def typegroup(%{constraint: constraint}) do
    Type.typegroup(constraint)
  end

  def compare(%{constraint: constraint}, rhs) do
    case Type.compare(constraint, rhs) do
      :eq -> :lt
      comp -> comp
    end
  end

  import Type

  intersection do
    def intersection(%Var{}, %Var{}) do
      raise "can't intersect two var types"
    end

    def intersection(left = %Var{}, right) do
      case Type.intersection(left.constraint, right) do
        builtin(:none) -> builtin(:none)
        type -> %{left | constraint: type}
      end
    end
  end

  def subtype?(_, _) do
    raise "what"
  end

  def usable_as(_, _, _meta) do
    raise "nope"
  end
end
