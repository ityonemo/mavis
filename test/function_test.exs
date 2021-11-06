#defmodule TypeTest.FunctionTest do
#  use ExUnit.Case, async: true
#  use Type.Operators
#
#  import Type, only: :macros
#
#  alias Type.{Function, FunctionError}
#
#  describe "the apply_types/3 function" do
#    @zero_arity type(( -> pos_integer()))
#    test "works with a zero arity function" do
#      assert {:ok, pos_integer()} == Function.apply_types(@zero_arity, [])
#    end
#
#    @one_arity type((pos_integer() -> pos_integer()))
#    test "works trivially with a one arity function" do
#      assert {:ok, pos_integer()} ==
#        Function.apply_types(@one_arity, [pos_integer()])
#    end
#
#    test "if there is an underspecified parameter it works" do
#      assert {:ok, pos_integer()} =
#        Function.apply_types(@one_arity, [1..10])
#    end
#
#    test "when there is a simple overspecified parameter it works" do
#      assert {:maybe, 1, [%Type.Message{
#        type: 1..10,
#        target: 1,
#        meta: _}]} = Function.apply_types(type((1 -> 1)), [1..10])
#    end
#
#    test "when there is an compound overspecified parameter it works" do
#      assert {:maybe, pos_integer(), [%Type.Message{
#        type: integer(),
#        target: pos_integer(),
#        meta: meta}]} = Function.apply_types(@one_arity, [integer()])
#
#      assert meta[:message] =~ "integer() is overbroad for argument 1 (pos_integer()) of function"
#    end
#
#    test "when there is an disjoint parameter it says error" do
#      assert {:error, %Type.Message{
#        type: -42..-1,
#        target: pos_integer(),
#        meta: meta
#      }} = Function.apply_types(@one_arity, [-42..-1])
#
#      assert meta[:message] =~ "-42..-1 is disjoint to argument 1 (pos_integer()) of function"
#    end
#
#    # simulate a compound function
#    @simulated_neg type((pos_integer() -> neg_integer())) <|>
#                   type((neg_integer() -> pos_integer())) <|>
#                   type((0 -> 0))
#
#    test "compound functions work on parameters hitting one partition" do
#      assert {:ok, neg_integer()} ==
#        Function.apply_types(@simulated_neg, [pos_integer()])
#      assert {:ok, pos_integer()} ==
#        Function.apply_types(@simulated_neg, [-10..-1])
#    end
#
#    test "compound functions work on parameters hitting multiple partitions" do
#      assert {:ok, integer()} ==
#        Function.apply_types(@simulated_neg, [integer()])
#      assert {:ok, 0 <|> neg_integer()} ==
#        Function.apply_types(@simulated_neg, [non_neg_integer()])
#      assert {:ok, non_neg_integer()} ==
#        Function.apply_types(@simulated_neg, [-10..0])
#    end
#
#    test "for compound functions overbroad parameters are maybe" do
#      # note that timeout has ":infinity"
#      assert {:maybe,
#              %Type.Union{of: [0, neg_integer()]},
#              [%Type.Message{type: timeout(),
#                             target: integer(),
#                             meta: meta}]} =
#        Function.apply_types(@simulated_neg, [timeout()])
#
#      assert meta[:message] =~ "timeout() is overbroad for argument 1 (integer()) of"
#    end
#
#    test "for compound functions disjoint parameters trigger errors" do
#      assert {:error, %Type.Message{
#        type: pid(),
#        target: integer(),
#        meta: meta
#      }} = Function.apply_types(@simulated_neg, [pid()])
#
#      assert meta[:message] =~ "pid() is disjoint to argument 1 (integer()) of"
#    end
#
#    ## works with an arity/2 function
#    @simple_arity_2 type((float(), float() -> integer()))
#    test "works on a simple arity/2 function" do
#      assert {:ok, integer()} = Function.apply_types(@simple_arity_2,
#        [float(), float()])
#    end
#
#    @compound_arity_2 type((pos_integer(), pos_integer() -> pos_integer())) <|>
#                      type((pos_integer(), 0 -> pos_integer())) <|>
#                      type((0, pos_integer() -> pos_integer())) <|>
#                      type((0, 0 -> 0))
#    test "works on a compound arity/2 function" do
#      assert {:ok, pos_integer()} = Function.apply_types(@compound_arity_2,
#        [pos_integer(), non_neg_integer()])
#    end
#    test "maybe works on overdetermined parameters to a compound arity/2 function" do
#      assert {:maybe, non_neg_integer(), [_]} =
#        Function.apply_types(@compound_arity_2, [non_neg_integer(), timeout()])
#    end
#
#    ## RAISING
#    @arity0_msg "mismatched arity; ( -> pos_integer()) expects 0 parameters, got 1 parameter [integer()]"
#    @arity1_msg "mismatched arity; (pos_integer() -> pos_integer()) expects 1 parameter, got 0 parameters []"
#    test "raises with FunctionError when the arity is mismatched" do
#      assert_raise FunctionError, @arity0_msg, fn ->
#        Function.apply_types(@zero_arity, [integer()])
#      end
#
#      assert_raise FunctionError, @arity1_msg, fn ->
#        Function.apply_types(type((pos_integer() -> pos_integer())), [])
#      end
#    end
#
#    @anyfn_msg "cannot apply a function with ... parameters"
#    test "raises with FunctionError when an any-arity function is supplied" do
#      assert_raise FunctionError, @anyfn_msg, fn ->
#        Function.apply_types(type(), [])
#      end
#      assert_raise FunctionError, @anyfn_msg, fn ->
#        Function.apply_types(type(), [integer()])
#      end
#    end
#  end
#end
#
