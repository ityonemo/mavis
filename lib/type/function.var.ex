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

  group_compare do
    def group_compare(_, _) do
      raise "hell"
    end
  end

  def intersection(_, _) do
    raise "cain"
  end

  def subtype?(_, _) do
    raise "what"
  end

  def usable_as(_, _, _meta) do
    raise "nope"
  end
end
