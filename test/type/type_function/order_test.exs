defmodule TypeTest.TypeFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Function
#
#  describe "a nonempty true list" do
#    test "is bigger than bottom and reference" do
#      assert nonempty(type: builtin(:any)) > builtin(:none)
#      assert nonempty(type: builtin(:any)) > builtin(:reference)
#    end
#
#    test "is bigger than a list which is a subclass" do
#      assert nonempty(type: builtin(:any)) > nonempty(type: builtin(:integer))
#      # because the final is more general
#      assert nonempty(type: builtin(:any), final: builtin(:any)) >
#        nonempty(type: builtin(:any))
#    end
#
#    test "is smaller than a list which is a superclass" do
#      assert nonempty(type: builtin(:integer)) < nonempty(type: builtin(:any))
#      assert nonempty(type: builtin(:integer)) < %List{type: builtin(:integer)}
#      # because the final is more general
#      assert nonempty(type: builtin(:any)) <
#        nonempty(type: builtin(:any), final: builtin(:any))
#    end
#
#    test "is smaller than maybe-empty lists, bitstrings or top" do
#      assert nonempty(type: builtin(:any)) < %List{type: builtin(:integer)}
#      assert nonempty(type: builtin(:any)) < %Type.Bitstring{size: 0, unit: 0}
#      assert nonempty(type: builtin(:any)) < builtin(:top)
#    end
#  end
#

  defp param_any_fn(return) do
    %Function{return: return, params: :any}
  end

  describe "a params any false list" do
    test "is bigger than bottom and reference" do
      assert param_any_fn(builtin(:any)) > builtin(:none)
      assert param_any_fn(builtin(:any)) > builtin(:reference)
    end

#    test "is bigger than a list which is empty: true" do
#      assert %List{type: builtin(:integer)} > nonempty(type: builtin(:any))
#    end
#
#    test "is bigger than a list which is a subclass" do
#      assert %List{type: builtin(:any)} > %List{type: builtin(:integer)}
#      # because the final is more general
#      assert %List{type: builtin(:any), final: builtin(:any)} >
#        %List{type: builtin(:any)}
#    end
#
#    test "is smaller than a list which is a superclass" do
#      assert %List{type: builtin(:integer)} < %List{type: builtin(:any)}
#      # because the final is more general
#      assert %List{type: builtin(:any)} <
#        %List{type: builtin(:any), final: builtin(:any)}
#    end
#
    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert param_any_fn(builtin(:any)) < builtin(:port)
      assert param_any_fn(builtin(:any)) < builtin(:any)
    end
  end

end
