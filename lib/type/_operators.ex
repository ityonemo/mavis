defmodule Type.Operators do
  @moduledoc """
  Convenience functions.  Should only be used in testing.
  """

  @kernel_operators [>: 2, <: 2, <=: 2, >=: 2, -: 2, in: 2]
  @basic_operators [<~>: 2, <|>: 2, ~>: 2]

  defmacro __using__(opts) do
    kernel_operators = case Keyword.get(opts, :only, :extended) do
      :basic ->
        []
      :extended ->
        @kernel_operators
    end
    all_operators = kernel_operators ++ @basic_operators

    quote do
      import Kernel, except: unquote(kernel_operators)
      import Type.Operators, only: unquote(all_operators)
    end
  end

  import Kernel, except: [>: 2, <: 2, <=: 2, >=: 2, -: 2, in: 2]

  @doc """
  Shortcut for `Type.usable_as/2`
  """
  defdelegate a ~> b, to: Type, as: :usable_as

  @doc """
  Shortcut for `Type.union/2`
  """
  defdelegate a <|> b, to: Type, as: :union

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

  @doc """
  shortcut for `Type.subtract/2`
  """
  defdelegate a - b, to: Type, as: :subtract
end
