defmodule Type.Operators do
  @moduledoc """
  Convenience functions.  Should only be used in testing.
  """

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [>: 2, <: 2, <=: 2, >=: 2, in: 2]
      import Type.Operators, only: [<~>: 2, <|>: 2, ~>: 2, >: 2, <: 2, <=: 2, >=: 2, in: 2]
    end
  end

  import Kernel, except: [>: 2, <: 2, <=: 2, >=: 2, in: 2]

  @doc """
  Shortcut for `Type.usable_as/2`
  """
  def a ~> b, do: Type.usable_as(a, b)

  @doc """
  Shortcut for `Type.union/2`
  """
  defdelegate a <|> b, to: Type.Union, as: :of

  @doc """
  Shortcut for `Type.intersection/2`
  """
  defdelegate a <~> b, to: Type, as: :intersection

  @doc """
  Shortcut for `Type.compare/2`
  """
  def a >= b, do: Type.compare(a, b) != :lt
  def a <= b, do: Type.compare(a, b) != :gt
  def a > b, do: Type.compare(a, b) == :gt
  def a < b, do: Type.compare(a, b) == :lt

  @doc """
  shortcut for `Type.subtype?/2`
  """
  defdelegate a in b, to: Type, as: :subtype?
end
