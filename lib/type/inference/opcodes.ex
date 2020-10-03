defmodule Type.Inference.Opcodes do

  import Type, only: :macros

  def forward({:move, {:x, from}, {:x, to}}, regs) do
    Map.put(regs, to, regs[from])
  end

  def forward({:move, {_, literal}, {:x, to}}, regs) do
    Map.put(regs, to, Type.of(literal))
  end

  def forward({:gc_bif, :bit_size, {:f, to}, 1, _, _}, regs) do
    Map.put(regs, to, builtin(:non_neg_integer))
  end

  def forward({:func_info, _, _, _}, regs), do: regs

  def forward({:line, line}, regs) do
    Map.put(regs, :line, line)
  end
  def forward({:label, _}, regs), do: regs
  def forward(:return, regs), do: regs

  ##############################################################

  def backprop({:move, {:x, from}, {:x, to}}, latest, prev) do
    Map.merge(prev, %{from => latest[to], to => builtin(:any)})
  end

  def backprop({:move, _, {:x, to}}, _, prev) do
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
