defmodule TypeTest.FunctionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  import Type, only: :macros

  alias Type.{Function, FunctionError}

  describe "the apply_types/3 function" do
    @zero_arity function(( -> builtin(:pos_integer)))
    test "works with a zero arity function" do
      assert {:ok, builtin(:pos_integer)} == Function.apply_types(@zero_arity, [])
    end

    @one_arity function((builtin(:pos_integer) -> builtin(:pos_integer)))
    test "works trivially with a one arity function" do
      assert {:ok, builtin(:pos_integer)} ==
        Function.apply_types(@one_arity, [builtin(:pos_integer)])
    end

    test "if there is an underspecified parameter it works" do
      assert {:ok, builtin(:pos_integer)} =
        Function.apply_types(@one_arity, [1..10])
    end

    test "when there is a simple overspecified parameter it works" do
      assert {:maybe, 1, [%Type.Message{
        type: 1..10,
        target: 1,
        meta: _}]} = Function.apply_types(function((1 -> 1)), [1..10])
    end

    test "when there is an compound overspecified parameter it works" do
      assert {:maybe, builtin(:pos_integer), [%Type.Message{
        type: builtin(:integer),
        target: builtin(:pos_integer),
        meta: meta}]} = Function.apply_types(@one_arity, [builtin(:integer)])

      assert meta[:message] =~ "integer() is overbroad for argument 1 (pos_integer()) of function"
    end

    test "when there is an disjoint parameter it says error" do
      assert {:error, %Type.Message{
        type: -42..-1,
        target: builtin(:pos_integer),
        meta: meta
      }} = Function.apply_types(@one_arity, [-42..-1])

      assert meta[:message] =~ "-42..-1 is disjoint to argument 1 (pos_integer()) of function"
    end

    # simulate a compound function
    @simulated_neg function((builtin(:pos_integer) -> builtin(:neg_integer))) <|>
                   function((builtin(:neg_integer) -> builtin(:pos_integer))) <|>
                   function((0 -> 0))

    test "compound functions work on parameters hitting one partition" do
      assert {:ok, builtin(:neg_integer)} ==
        Function.apply_types(@simulated_neg, [builtin(:pos_integer)])
      assert {:ok, builtin(:pos_integer)} ==
        Function.apply_types(@simulated_neg, [-10..-1])
    end

    test "compound functions work on parameters hitting multiple partitions" do
      assert {:ok, builtin(:integer)} ==
        Function.apply_types(@simulated_neg, [builtin(:integer)])
      assert {:ok, 0 <|> builtin(:neg_integer)} ==
        Function.apply_types(@simulated_neg, [builtin(:non_neg_integer)])
      assert {:ok, builtin(:non_neg_integer)} ==
        Function.apply_types(@simulated_neg, [-10..0])
    end

    test "for compound functions overbroad parameters are maybe" do
      # note that timeout has ":infinity"
      assert {:maybe,
              %Type.Union{of: [0, builtin(:neg_integer)]},
              [%Type.Message{type: builtin(:timeout),
                             target: builtin(:integer),
                             meta: meta}]} =
        Function.apply_types(@simulated_neg, [builtin(:timeout)])

      assert meta[:message] =~ "timeout() is overbroad for argument 1 (integer()) of"
    end
    
    test "for compound functions disjoint parameters trigger errors" do
      assert {:error, %Type.Message{
        type: builtin(:pid),
        target: builtin(:integer),
        meta: meta
      }} = Function.apply_types(@simulated_neg, [builtin(:pid)])

      assert meta[:message] =~ "pid() is disjoint to argument 1 (integer()) of"
    end

    ## works with an arity/2 function
    @simple_arity_2 function((builtin(:float), builtin(:float) -> builtin(:integer)))
    test "works on a simple arity/2 function" do
      assert {:ok, builtin(:integer)} = Function.apply_types(@simple_arity_2,
        [builtin(:float), builtin(:float)])
    end

    @compound_arity_2 function((builtin(:pos_integer), builtin(:pos_integer) -> builtin(:pos_integer))) <|>
                      function((builtin(:pos_integer), 0 -> builtin(:pos_integer))) <|>
                      function((0, builtin(:pos_integer) -> builtin(:pos_integer))) <|>
                      function((0, 0 -> 0))
    test "works on a compound arity/2 function" do
      assert {:ok, builtin(:pos_integer)} = Function.apply_types(@compound_arity_2,
        [builtin(:pos_integer), builtin(:non_neg_integer)])
    end
    test "maybe works on overdetermined parameters to a compound arity/2 function" do
      assert {:maybe, builtin(:non_neg_integer), [_]} =
        Function.apply_types(@compound_arity_2, [builtin(:non_neg_integer), builtin(:timeout)])
    end

    ## RAISING
    @arity0_msg "mismatched arity; ( -> pos_integer()) expects 0 parameters, got 1 parameter [integer()]"
    @arity1_msg "mismatched arity; (pos_integer() -> pos_integer()) expects 1 parameter, got 0 parameters []"
    test "raises with FunctionError when the arity is mismatched" do
      assert_raise FunctionError, @arity0_msg, fn ->
        Function.apply_types(@zero_arity, [builtin(:integer)])
      end

      assert_raise FunctionError, @arity1_msg, fn ->
        Function.apply_types(function((builtin(:pos_integer) -> builtin(:pos_integer))), [])
      end
    end

    @anyfn_msg "cannot apply a function with ... parameters"
    test "raises with FunctionError when an any-arity function is supplied" do
      assert_raise FunctionError, @anyfn_msg, fn ->
        Function.apply_types(builtin(:function), [])
      end
      assert_raise FunctionError, @anyfn_msg, fn ->
        Function.apply_types(builtin(:function), [builtin(:integer)])
      end
    end
  end
end
