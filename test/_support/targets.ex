defmodule TypeTest.Targets do

  import Type, only: :macros

  alias Type.{Bitstring, Function}

  @example_list [-47, neg_integer(), 0, 47, -10..10,
  pos_integer(), float(), :foo, atom(),
  reference(), %Function{params: [], return: 0}, port(),
  pid(), tuple({}), map(),
  [], list(), %Bitstring{size: 0, unit: 0}]

  def except(list \\ []) do
    Enum.reject(@example_list, &(&1 in list))
  end
end
