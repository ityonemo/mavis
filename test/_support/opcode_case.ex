defmodule TypeTest.OpcodeCase do
  # helper tools for testing opcodes.
  # this might wind up being in the main part of code.

  alias Type.Inference

  def shift(state = %Inference{code: [head | rest], stack: stack}) do
    %{state | code: rest, stack: [head | stack]}
  end
end
