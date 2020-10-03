defmodule Type.Inference.Api do

  @type opcode :: atom | tuple

  @callback forward(opcode, Type.Inference.reg_state) :: Type.Inference.reg_state
  @callback backprop(opcode, Type.Inference.reg_state) ::
    {:ok, Type.Inference.reg_state} |
    {:error, term}
end
