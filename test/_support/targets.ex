defmodule TypeTest.Targets do

  import Type, only: [builtin: 1]

  alias Type.{Bitstring, Function, List, Map, Tuple}

  @example_list [-47, builtin(:neg_integer), 0, 47, -10..10,
  builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer),
  builtin(:float), :foo, builtin(:atom), builtin(:reference),
  %Function{return: 0}, builtin(:port), builtin(:pid),
  %Tuple{elements: []}, Map.build(%{builtin(:any) => builtin(:any)}),
  [], %List{}, %Bitstring{size: 0, unit: 0}]

  def except(list \\ []) do
    Enum.reject(@example_list, &(&1 in list))
  end
end
