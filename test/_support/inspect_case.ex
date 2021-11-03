defmodule TypeTest.InspectCase do
  defmacro pull_types(module_ast) do
    parent = __CALLER__.module
    quote do
      {:module, module, bin, _} = unquote(module_ast)
      {:ok, {_, [debug_info: info]}} = :beam_lib.chunks(bin, [:debug_info])
      {_debug_ver, _elixir_erl, {_elixir_ver, _dbg_map, attrs}} = info

      Enum.each(attrs, fn
        {_, _, :type, {name, type, _}} ->
          Module.put_attribute(unquote(parent), name, Type.Spec.parse(type))
        {_, _, :opaque, {name, type, params}} ->
          Module.put_attribute(unquote(parent), name,
            %Type.Opaque{module: module, name: name, params: params, type: Type.Spec.parse(type)})
        {_, _, :spec, {{name, _arity}, branches}} ->
          # assume for our test cases we don't care about arity.
          Module.put_attribute(unquote(parent), name, Type.Spec.parse_spec(branches))
        _ ->
          :ok
      end)
    end
  end

  def eval_type_str(string) do
    string
    |> Code.eval_string([],
      functions: [
        {Kernel, Kernel.__info__(:functions)},
        {Type.Operators, [<|>: 2, <~>: 2]}
      ],
      macros: [
        {Kernel, Kernel.__info__(:macros)},
        {Type, Type.__info__(:macros)}
      ],
      requires: [Type])
    |> elem(0)
  end

  def eval_inspect(type_code) do
    type_code
    |> inspect
    |> eval_type_str
  end
end
