defmodule TypeTest.InspectCase do
  defmacro pull_types(module_ast) do
    parent = __CALLER__.module
    quote do
      {:module, _, bin, _} = unquote(module_ast)
      {:ok, {_, [debug_info: info]}} = :beam_lib.chunks(bin, [:debug_info])
      {_debug_ver, _elixir_erl, {_elixir_ver, _dbg_map, attrs}} = info

      Enum.each(attrs, fn
        {_, _, :type, {name, type, _}} ->
          Module.put_attribute(unquote(parent), name, Type.Spec.parse(type))
        {_, _, :spec, {{name, _arity}, branches}} ->
          # assume for our test cases we don't care about arity.
          Module.put_attribute(unquote(parent), name, Type.Spec.parse_spec(branches))
        _ -> :ok
      end)
    end
  end

  def eval_inspect(type_code) do
    macros = Type.__info__(:macros)
    type_code
    |> inspect
    |> Code.eval_string([],
      macros: [{Type, macros}],
      requires: [Type])
    |> elem(0)
  end
end
