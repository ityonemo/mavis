defmodule Type.Inference.Opcodes do

  import Type, only: :macros

  use Type.Inference.Macros

  opcode {:move, {:x, from}, {:x, to}} do
    forward(registers) do
      Map.put(registers, to, registers[from])
    end

    backprop(last, _prev) do
      Map.merge(last, %{from => last[to], to => builtin(:any)})
    end
  end

  opcode {:move, {_, literal}, {:x, to}} do
    forward(registers) do
      Map.put(registers, to, Type.of(literal))
    end

    backprop(last, _prev) do
      Map.merge(last, %{to => builtin(:any)})
    end
  end

  opcode {:gc_bif, :bit_size, {:f, to}, 1, [x: from], _} do
    forward(registers) do
      Map.put(registers, to, builtin(:non_neg_integer))
    end

    backprop(last, _prev) do
      Map.put(last, from, %Type.Bitstring{size: 0, unit: 1})
    end
  end

  opcode {:line, line} do
    forward(registers) do
      Map.put(registers, :line, line)
    end
  end

  opcode {:func_info, _, _, _}
  opcode {:label, _}
  opcode :return

end
