defmodule TypeTest.LambdaExamples do
  def identity_fn, do: &(&1)
  def identity(x), do: x
end
