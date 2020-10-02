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

  def backprop({:move, {:x, from}, {:x, to}}, latest, prev) do
    Map.merge(prev, %{from => latest[to], to => builtin(:any)})
  end

  def backprop({:move, {:integer, _}, {:x, to}}, _, prev) do
    Map.put(prev, to, builtin(:any))
  end

  def backprop({:move, {:atom, _}, {:x, to}}, _, prev) do
    Map.put(prev, to, builtin(:any))
  end

  def backprop({:move, {:literal, _}, {:x, to}}, _, prev) do
    Map.put(prev, to, builtin(:any))
  end

  def backprop({:gc_bif, :bit_size, _, 1, [x: from], _}, _latest, prev) do
    # TODO: type checking on latest to reject incorrect forms.
    Map.put(prev, from, %Type.Bitstring{size: 0, unit: 1})
  end

  def backprop({:func_info, _, _, _}, last, _), do: last
  def backprop({:line, _}, last, _), do: last
  def backprop({:label, _}, last, _), do: last
  def backprop(:return, last, _), do: last

end
