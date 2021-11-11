defmodule TypeTest.InspectCase do
  def eval_type_str(string) do
    string
    |> Code.eval_string([],
      functions: [
        {Kernel, Kernel.__info__(:functions)},
        {Type.Operators, [<|>: 2, <~>: 2, |||: 2]}
      ],
      macros: [
        {Kernel, Kernel.__info__(:macros)},
        {Type, Type.__info__(:macros)}
      ],
      requires: [Type, Type.Operators])
    |> elem(0)
  end

  def eval_inspect(type_code) do
    type_code
    |> inspect
    |> eval_type_str
  end
end
