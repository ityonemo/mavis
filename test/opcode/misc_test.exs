defmodule TypeTest.Opcode.MiscTest do

  # miscellaneous opcodes that don't do as much

  use ExUnit.Case, async: true

  @moduletag :opcodes

  import Type, only: :macros
  alias Type.{Function, Inference}

  def forward_idempotent?(instr, regs \\ [0]) do
    reg_map = regs
    |> Enum.map(fn idx -> {idx, builtin(:any)} end)
    |> Enum.into(%{})

    assert %{regs: [[reg_map] | _]} =
      Inference.Opcodes.forward(%Inference{
        code: [instr],
        regs: [[reg_map]]
      })
  end

  def backward_idempotent?(instr, regs \\ [0]) do
    reg_map = regs
    |> Enum.map(fn idx -> {idx, builtin(:any)} end)
    |> Enum.into(%{})

    assert %{regs: [[reg_map] | _]} =
      Inference.do_backprop(%Inference{
        code: [],
        stack: [instr],
        regs: [[reg_map], [reg_map]]
      })
  end

  describe "funcinfo opcode" do
    @func_info {:func_info, {:atom, :module}, {:atom, :func}, 2}
    test "is idempotent on forward pass" do
      assert forward_idempotent?(@func_info)
    end

    test "is idempotent on backprop pass" do
      assert backward_idempotent?(@func_info)
    end

    test "integration" do
      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run([@func_info], %{0 => builtin(:any)})
    end
  end

  describe "label opcode" do
    @label {:label, 47}

    test "is idempotent on forward pass" do
      assert forward_idempotent?(@label)
    end

    test "is idempotent on backprop pass" do
      assert backward_idempotent?(@label)
    end

    test "integration" do
      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run([@label], %{0 => builtin(:any)})
    end
  end

  describe "line opcode" do
    @line {:line, 47}

    test "is idempotent on forward pass" do
      assert forward_idempotent?(@line)
    end

    test "forward prop metadata" do
      reg_map = %{0 => builtin(:any)}

      assert %{meta: %{line: 47}} =
        Inference.Opcodes.forward(%Inference{
          code: [@line],
          regs: [[reg_map]]
        })
    end

    test "is idempotent on backprop pass" do
      assert backward_idempotent?(@line)
    end

    test "integration" do
      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run([@line], %{0 => builtin(:any)})
    end
  end

  describe "return opcode" do
    test "is idempotent on forward pass" do
      assert forward_idempotent?(:return)
    end

    test "is idempotent on backprop pass" do
      assert backward_idempotent?(:return)
    end

    test "integration" do
      assert {:ok, %Function{
        params: [builtin(:any)], return: builtin(:any)
      }} = Inference.run([:return], %{0 => builtin(:any)})
    end
  end
end
