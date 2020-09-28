defmodule TypeTest.LambdaExamples do
  def identity_fn, do: &(&1)
  def identity(x), do: x
  def with_move(x, y), do: y
  def with_add(x, y), do: x + y

  def with_bitsize(a), do: :erlang.bit_size(a)

  def forty_seven, do: 47
  def forty_seven_str, do: "forty seven"
end
