defmodule Type.Inference.Opcodes do

  import Type.Inference.Macros

  def forward(state = %{
    code: [{:move, {:x, from}, {:x, to}}],
    regs: old_registers = [[latest_registers] | _]
  }) do

    new_registers = Map.put(latest_registers, to, latest_registers[from])
    shift(%{state | regs: [[new_registers] | old_registers]})
  end
end
