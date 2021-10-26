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
        _ -> :ok
      end)
    end
  end

  def eval_inspect(type_code) do
    code_str = inspect(type_code)
    code = if code_str =~ "(" do
      "Type.#{type_code}"
    else
      code_str
    end

    code
    |> Code.eval_string
    |> elem(0)
  end
end
