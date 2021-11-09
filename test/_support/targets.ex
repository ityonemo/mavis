defmodule TypeTest.Targets do

  import Type, only: :macros

  alias Type.Bitstring

  @example_list [-47, neg_integer(), 0, 47, -10..10,
  pos_integer(), float(), 47.0, :foo, atom(),
  reference(), type(( -> 0)), port(),
  pid(), type({}), map(),
  [], ["foo", "bar"], list(),
  "foo", <<0::7>>, %Bitstring{size: 0, unit: 0}]

  def except(list \\ []) do
    Enum.reject(@example_list, &(&1 in list))
  end
end
