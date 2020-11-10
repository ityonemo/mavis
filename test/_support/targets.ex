defmodule TypeTest.Targets do

  import Type, only: :macros

  alias Type.Bitstring

  @example_list [-47, builtin(:neg_integer), 0, 47, -10..10,
  builtin(:pos_integer), builtin(:float), :foo, builtin(:atom),
  builtin(:reference), function(( -> 0)), builtin(:port),
  builtin(:pid), tuple({}), builtin(:map),
  [], builtin(:list), %Bitstring{size: 0, unit: 0}]

  def except(list \\ []) do
    Enum.reject(@example_list, &(&1 in list))
  end
end
