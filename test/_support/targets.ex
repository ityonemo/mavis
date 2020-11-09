defmodule TypeTest.Targets do

  import Type, only: :macros

  alias Type.{Bitstring, Function, List, Map, Tuple}

  @example_list [-47, builtin(:neg_integer), 0, 47, -10..10,
  builtin(:pos_integer), builtin(:float), :foo, builtin(:atom),
  builtin(:reference), %Function{params: [], return: 0}, builtin(:port),
  builtin(:pid), tuple({}), builtin(:map),
  [], %List{}, %Bitstring{size: 0, unit: 0}]

  def except(list \\ []) do
    Enum.reject(@example_list, &(&1 in list))
  end
end
