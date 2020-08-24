defprotocol Type.Typeable do
  def of(data, context)
end

defimpl Type.Typeable, for: BitString do
  # NB literal bitstrings can only happen in the AST when they are
  # elixir-style UTF-8 binaries.  Otherwise they are created using
  # the <<>> notation.
  def of(_binary, _), do: %Type{name: :t, module: String}
end
defimpl Type.Typeable, for: Atom do
  def of(atom, _), do: %Type{name: atom, module: :atom}
end
defimpl Type.Typeable, for: Integer do
  def of(integer, _), do: integer
end
defimpl Type.Typeable, for: Float do
  def of(_float, _), do: %Type{name: :float}
end

defimpl Type.Typeable, for: Tuple do
  @builtin_types ~w"""
  any none pid port reference
  float integer neg_integer non_neg_integer pos_integer
  atom module node
  iolist
  """a

  # NB: iolist is special-cased since it's the only builtin type that
  # is recursive, otherwise it would be "reducible".  In order to
  # correctly handle recursive types, types need to be able to be 'named'
  # and currently we don't allow builtin types to be named (for simplicity).

  @char_range 0..0x10FFFF

  @reducible_types %{
    arity: 0..255, byte: 0..255, char: @char_range,
    number: %Type.Union{of: [%Type{name: :float}, %Type{name: :integer}]},
    timeout: %Type.Union{of: [:infinity, %Type{name: :integer}]},
    boolean: %Type.Union{of: [false, true]},
    mfa: %Type.Tuple{elements: [%Type{name: :module}, %Type{name: :atom}, 0..255]},
    identifier: %Type.Union{of: [%Type{name: :pid}, %Type{name: :port}, %Type{name: :reference}]},
    binary: %Type.Bitstring{size: 0, unit: 8},
    bitstring: %Type.Bitstring{size: 0, unit: 1},
    iodata: %Type.Union{of:
      [%Type.Bitstring{size: 0, unit: 8}, %Type{name: :iolist}]},
    term: %Type{name: :any}
  }
  @reducible_keys Map.keys(@reducible_types)

  # four-tuples are fetched values from typespecs
  def of({:type, _, builtin, []}, _) when builtin in @builtin_types do
    %Type{name: builtin}
  end
  def of({:type, _, f, []}, _) when f in [:fun, :function] do
    %Type.Function{params: :any, return: %Type{name: :any}}
  end
  def of({:type, _, special, []}, _) when special in @reducible_keys do
    @reducible_types[special]
  end
  # generic functions
  def of({:type, _, :fun, [{:type, _, :product, params}, result]}, context) do
    %Type.Function{
      params: Enum.map(params, &Type.of(&1, context)),
      return: Type.of(result, context)
    }
  end
  # special any-arity functions
  def of({:type, _, :fun, [{:type, _, :any}, result]}, context) do
    %Type.Function{
      params: :any,
      return: Type.of(result, context)
    }
  end
  def of({:type, _, :tuple, :any}, _env) do
    %Type.Tuple{elements: :any}
  end
  def of({:type, _, :tuple, elements}, env) do
    %Type.Tuple{elements: Enum.map(elements, &Type.of(&1, env))}
  end
  def of({:type, _, :range, [{:integer, _, first}, {:integer, _, last}]}, _) do
    first..last
  end
  def of({:type, _, :union, types}, env) do
    %Type.Union{of: Enum.map(types, &Type.of(&1, env))}
  end
  # empty list is strange.
  def of({:type, _, nil, []}, _env), do: []
  def of({:type, _, :list, [type]}, env) do
    %Type.List{type: Type.of(type, env)}
  end
  def of({:type, _, :nonempty_list, []}, _env) do
    %Type.List{nonempty: true, type: %Type{name: :any}}
  end
  def of({:type, _, :nonempty_list, [type]}, env) do
    %Type.List{nonempty: true, type: Type.of(type, env)}
  end
  def of({:type, _, :maybe_improper_list, []}, _env) do
    %Type.List{
      nonempty: false,
      type: %Type{name: :any},
      final: Type.Union.of([], %Type{name: :any})}
  end
  def of({:type, _, :maybe_improper_list, [main, final]}, env) do
    %Type.List{
      nonempty: false,
      type: Type.of(main, env),
      final: Type.Union.of([], Type.of(final, env))}
  end
  def of({:type, _, :nonempty_improper_list, [main, final]}, env) do
    %Type.List{
      nonempty: true,
      type: Type.of(main, env),
      final: Type.of(final, env)}
  end
  def of({:type, _, :nonempty_maybe_improper_list, []}, _env) do
    %Type.List{
      nonempty: true,
      type: %Type{name: :any},
      final: Type.Union.of([], %Type{name: :any})}
  end
  def of({:type, _, :nonempty_maybe_improper_list, [main, final]}, env) do
    %Type.List{
      nonempty: true,
      type: Type.of(main, env),
      final: Type.Union.of([], Type.of(final, env))}
  end
  def of({:type, _, :binary, [{:integer, _, size}, {:integer, _, unit}]}, _env) do
    %Type.Bitstring{size: size, unit: unit}
  end
  def of({:type, _, :map, :any}, _env) do
    %Type.Map{kv: [optional: {%Type{name: :any}, %Type{name: :any}}]}
  end
  def of({:type, _, :map, lst}, env) when is_list(lst) do
    %Type.Map{kv: Enum.map(lst, &type_to_kv_spec(&1, env))}
  end
  def of({:user_type, _, name, params}, env) do
    %Type{
      name: name,
      module: env.module,
      params: Enum.map(params, &Type.of(&1, env))
    }
  end
  def of({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :charlist}, []]}, _env) do
    %Type.List{type: @char_range}
  end
  def of({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :nonempty_charlist}, []]}, _env) do
    %Type.List{nonempty: true, type: @char_range}
  end
  def of({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, params]}, env) do
    value_type = case params do
      [] -> %Type{name: :any}
      [type] -> Type.of(type, env)
    end
    %Type.List{type: %Type.Tuple{elements: [%Type{name: :atom}, value_type]}}
  end
  def of({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :as_boolean}, [type]]}, env) do
    %Type.AsBoolean{for: Type.of(type, env)}
  end
  def of({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :struct}, params]}, _env) do
    %Type.Map{kv: [
      required: {:__struct__, %Type{name: :atom}},
      optional: {%Type{name: :atom}, %Type{name: :any}}]}
  end
  def of({:remote_type, _, [{:atom, _, mod}, {:atom, _, type}, params]}, env) do
    %Type{module: mod, name: type, params: Enum.map(params, &Type.of(&1, env))}
  end
  # some literals are 3-tples
  def of({:integer, _, integer}, %{context: :fetch}) when is_integer(integer) do
    integer
  end
  def of({:atom, _, atom}, %{context: :fetch}) when is_atom(atom) do
    atom
  end
  def of(type, env = %{context: :fetch}) do
    raise "unexpected type retrieval #{inspect type}"
  end

  # we can also pull information from when we are inside a spec
  @basic_types ~w(integer)a
  def of({type, _meta, atom}, %{context: :spec}) when is_atom(atom) and type in @basic_types do
    %Type{name: type}
  end
  def of({{:., _, [a = {:__aliases__, _, _}, name]}, _, params}, env = %{context: :spec}) do
    %Type{
      module: Macro.expand(a, env),
      name: name,
      params: Enum.map(params, &Type.of(&1, env))
    }
  end
  def of(ast, %{context: :spec}) do
    raise "unexpected ast for spec"
  end

  # three-tuples with atom in last position are variables to be pulled
  # from the context.
  def of({variable, _meta, atom}, env) when is_atom(atom) do
    env.contextual_vars[variable]
  end

  def type_to_kv_spec({:type, _, :map_field_exact, [k, v]}, env) do
    {:required, {Type.of(k, env), Type.of(v, env)}}
  end
  def type_to_kv_spec({:type, _, :map_field_assoc, [k, v]}, env) do
    {:optional, {Type.of(k, env), Type.of(v, env)}}
  end

end
