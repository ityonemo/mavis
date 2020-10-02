defmodule Type.Inference.Opcodes do

  import Type.Inference.Macros
  import Type, only: :macros

  def forward(state = %{
    code: [{:move, {:x, from}, {:x, to}} | _],
    regs: old_registers = [[latest_registers] | _]
  }) do

    new_registers = Map.put(latest_registers, to, latest_registers[from])
    shift(%{state | regs: [[new_registers] | old_registers]})
  end

  def forward(state = %{
    code: [{:move, {:integer, literal}, {:x, to}} | _],
    regs: old_registers = [[latest_registers] | _]
  }) do

    new_registers = Map.put(latest_registers, to, literal)
    shift(%{state | regs: [[new_registers] | old_registers]})
  end

  def forward(state = %{
    code: [{:move, {:atom, literal}, {:x, to}} | _],
    regs: old_registers = [[latest_registers] | _]
  }) do

    new_registers = Map.put(latest_registers, to, literal)
    shift(%{state | regs: [[new_registers] | old_registers]})
  end

  def forward(state = %{
    code: [{:move, {:literal, literal}, {:x, to}} | _],
    regs: old_registers = [[latest_registers] | _]
  }) do

    new_registers = Map.put(latest_registers, to, Type.of(literal))
    shift(%{state | regs: [[new_registers] | old_registers]})
  end

  def forward(state = %{
    code: [{:gc_bif, :bit_size, {:f, to}, 1, _, _} | _],
    regs: old_registers = [[latest_registers] | _]
  }) do

    new_registers = Map.put(latest_registers, to, builtin(:non_neg_integer))
    shift(%{state | regs: [[new_registers] | old_registers]})
  end

  def forward(state = %{code: [{:func_info, _, _, _} | _]}) do
    state
    |> push_same_reg()
    |> shift()
  end

  def forward(state = %{code: [{:line, line} | _]}) do
    state
    |> push_meta(:line, line)
    |> push_same_reg()
    |> shift()
  end

  def forward(state = %{code: [{:label, _} | _]}) do
    state
    |> push_same_reg()
    |> shift()
  end

  def forward(state = %{code: [:return | _]}) do
    state
    |> push_same_reg()
    |> shift()
  end

  ##############################################################

  def backprop(state = %{
    stack: [{:move, {:x, from}, {:x, to}} | _],
    regs: [[latest_registers], [registers_to_change] | _]
  }) do
    substituted_registers = Map.merge(registers_to_change,
      %{from => latest_registers[to], to => builtin(:any)})

    state
    |> pop_reg_replace([substituted_registers])
    |> unshift
  end

  def backprop(state = %{
    stack: [{:move, {:integer, _}, {:x, to}} | _],
    regs: [_, [registers_to_change] | _]
  }) do
    substituted_registers = Map.put(registers_to_change, to, builtin(:any))

    state
    |> pop_reg_replace([substituted_registers])
    |> unshift
  end

  def backprop(state = %{
    stack: [{:move, {:atom, _}, {:x, to}} | _],
    regs: [_, [registers_to_change] | _]
  }) do
    substituted_registers = Map.put(registers_to_change, to, builtin(:any))

    state
    |> pop_reg_replace([substituted_registers])
    |> unshift
  end

  def backprop(state = %{
    stack: [{:move, {:literal, _}, {:x, to}} | _],
    regs: [_, [registers_to_change] | _]
  }) do
    substituted_registers = Map.put(registers_to_change, to, builtin(:any))

    state
    |> pop_reg_replace([substituted_registers])
    |> unshift
  end

  def backprop(state = %{
    stack: [{:gc_bif, :bit_size, _, 1, [x: from], _} | _],
    regs: old_registers = [_, [registers_to_change] | _]
  }) do
    substituted_registers = Map.put(
      registers_to_change, from, %Type.Bitstring{size: 0, unit: 1})

    state
    |> pop_reg_replace([substituted_registers])
  end

  def backprop(state = %{stack: [{:func_info, _, _, _} | _]}) do
    state
    |> pop_reg
    |> unshift
  end

  def backprop(state = %{stack: [{:line, _} | _]}) do
    state
    |> pop_reg
    |> unshift
  end

  def backprop(state = %{stack: [{:label, _} | _]}) do
    state
    |> pop_reg
    |> unshift
  end

  def backprop(state = %{stack: [:return | _]}) do
    state
    |> pop_reg
    |> unshift
  end

end
