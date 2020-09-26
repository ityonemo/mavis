defmodule Type.Operators do
  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [>: 2, <: 2, <=: 2, >=: 2, in: 2]
      import Type.Operators, only: [|: 2, ~>: 2, >: 2, <: 2, <=: 2, >=: 2, in: 2]
    end
  end

  import Kernel, except: [>: 2, <: 2, <=: 2, >=: 2, in: 2]

  @doc """
  shortcut for `Type.Properties.usable_as/2`
  """
  def a ~> b, do: Type.usable_as(a, b)

  @doc """
  shortcut for `Type.Union.of/2`
  """
  defdelegate a | b, to: Type.Union, as: :of

  @doc """
  shortcut for `Type.compare/2`
  """
  def a >= b, do: Type.compare(a, b) in [:gt, :eq]
  def a <= b, do: Type.compare(a, b) in [:lt, :eq]
  def a > b, do: Type.compare(a, b) == :gt
  def a < b, do: Type.compare(a, b) == :lt

  @doc """
  shortcut for `Type.subtype?/2`
  """
  defdelegate a in b, to: Type, as: :subtype?
end
