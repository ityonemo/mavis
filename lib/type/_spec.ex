defmodule Type.Spec do

  import Type, only: :macros

  def parse(spec, assigns \\ %{})
  def parse({:type, _, :map, :any}, _assigns) do
    struct(Type.Map, optional: builtin(:any))
  end
  def parse({:type, _, :map, params}, assigns) when is_list(params) do
    Enum.reduce(params, struct(Type.Map), fn
      {:type, _, :map_field_assoc, [src_type, dst_type]}, map = %{optional: optional} ->
        %{map | optional: Map.put(optional, parse(src_type, assigns), parse(dst_type, assigns))}
      {:type, _, :map_field_exact, [src_type, dst_type]}, map = %{required: required} ->
        %{map | required: Map.put(required, parse(src_type, assigns), parse(dst_type, assigns))}
    end)
  end

  # fix assigns
  def parse({:var, _, name}, assigns) when is_map_key(assigns, name) do
    assigns[name]
  end
  def parse({:var, _, :_}, _assigns) do
    builtin(:any)
  end
  def parse({:var, _, name}, assigns) when is_map_key(assigns, {name, :subtype_of}) do
    struct(Type.Function.Var, name: name, constraint: assigns[{name, :subtype_of}])
  end
  def parse({:var, _, name}, _assigns) do
    struct(Type.Function.Var, name: name)
  end
  # general types
  def parse({:type, _, :range, [first, last]}, assigns), do: parse(first, assigns)..parse(last, assigns)
  def parse({:op, _, :-, value}, assigns), do: -parse(value, assigns)
  def parse({:integer, _, value}, _), do: value
  def parse({:atom, _, value}, _), do: value
  def parse({:type, _, :fun, [{:type, _, :any}, return]}, assigns) do
    struct(Type.Function, params: :any, return: parse(return, assigns))
  end
  def parse({:type, _, :fun, [{:type, _, :product, params}, return]}, assigns) do
    param_types = Enum.map(params, &parse(&1, assigns))
    struct(Type.Function, params: param_types, return: parse(return, assigns))
  end
  def parse({:type, _, :tuple, :any}, _) do
    struct(Type.Tuple, elements: :any)
  end
  def parse({:type, _, :tuple, elements}, assigns) do
    struct(Type.Tuple, elements: Enum.map(elements, &parse(&1, assigns)))
  end
  # empty list
  def parse({:type, _, nil, []}, _), do: []
  # overrides
  def parse({:type, _, :no_return, []}, _), do: builtin(:none)
  def parse({:type, _, :term, []}, _), do: builtin(:any)
  def parse({:type, _, :arity, []}, _), do: 0..255
  def parse({:type, _, :byte, []}, _), do: 0..255
  def parse({:type, _, :char, []}, _), do: 0..0x10FFFF
  def parse({:type, _, :number, []}, _) do
    Type.Union.of(builtin(:integer), builtin(:float))
  end
  def parse({:type, _, :timeout, []}, _) do
    Type.Union.of(builtin(:non_neg_integer), :infinity)
  end
  def parse({:type, _, :identifier, []}, _) do
    ~w(port pid reference)a
    |> Enum.map(&builtin/1)
    |> Enum.into(struct(Type.Union))
  end
  def parse({:type, _, :boolean, []}, _) do
    Type.Union.of(true, false)
  end
  def parse({:type, _, :fun, []}, _) do
    struct(Type.Function, params: :any, return: builtin(:any))
  end
  def parse({:type, _, :function, []}, _) do
    struct(Type.Function, params: :any, return: builtin(:any))
  end
  def parse({:type, _, :mfa, []}, _) do
    struct(Type.Tuple, elements: [builtin(:module), builtin(:atom), 0..255])
  end
  def parse({:type, _, :list, []}, _) do
    struct(Type.List, type: builtin(:any))
  end
  def parse({:type, _, :list, [type]}, assigns) do
    struct(Type.List, type: parse(type, assigns))
  end
  def parse({:type, _, :nonempty_list, []}, _) do
    struct(Type.List, type: builtin(:any), nonempty: true)
  end
  def parse({:type, _, :nonempty_list, [type]}, assigns) do
    struct(Type.List, type: parse(type, assigns), nonempty: true)
  end

  def parse({:type, _, :maybe_improper_list, []}, _) do
    struct(Type.List, final: builtin(:any))
  end
  def parse({:type, _, :maybe_improper_list, [type, final]}, assigns) do
    struct(Type.List,
      type: parse(type, assigns),
      final: Type.Union.of(parse(final, assigns), []))
  end
  def parse({:type, _, :nonempty_improper_list, [type, final]}, assigns) do
    struct(Type.List,
      type: parse(type, assigns),
      nonempty: true,
      final: parse(final, assigns))
  end
  def parse({:type, _, :nonempty_maybe_improper_list, []}, _) do
    struct(Type.List, nonempty: true, final: builtin(:any))
  end
  def parse({:type, _, :nonempty_maybe_improper_list, [type, final]}, assigns) do
    struct(Type.List,
      type: parse(type, assigns),
      nonempty: true,
      final: Type.Union.of(parse(final, assigns), []))
  end
  def parse({:type, _, :bitstring, []}, _) do
    struct(Type.Bitstring, size: 0, unit: 1)
  end
  def parse({:type, _, :binary, []}, _) do
    struct(Type.Bitstring, size: 0, unit: 8)
  end
  def parse({:type, _, :binary, [size, unit]}, assigns) do
    struct(Type.Bitstring, size: parse(size, assigns), unit: parse(unit, assigns))
  end
  def parse({:type, _, :iodata, []}, _) do
    Type.Union.of(struct(Type.Bitstring, size: 0, unit: 8), builtin(:iolist))
  end
  def parse({:type, _, :union, types}, assigns) do
    types
    |> Enum.map(&parse(&1, assigns))
    |> Enum.into(struct(Type.Union))
  end
  # overridden remote types
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :charlist}, []]}, _) do
    struct(Type.List, type: 0..0x10FFFF)
  end
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :nonempty_charlist}, []]}, _) do
    struct(Type.List, type: 0..0x10FFFF, nonempty: true)
  end
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, []]}, _) do
    struct(Type.List, type: struct(Type.Tuple, elements: [builtin(:atom), builtin(:any)]))
  end
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, [type]]}, assigns) do
    struct(Type.List, type: struct(Type.Tuple, elements: [builtin(:atom), parse(type, assigns)]))
  end
  # general remote type
  def parse({:remote_type, _, [module, name, args]}, assigns) do
    %Type{module: parse(module, assigns),
          name: parse(name, assigns),
          params: Enum.map(args, &parse(&1, assigns))}
  end
  # general local type
  def parse({:user_type, _, name, args}, assigns) do
    %Type{module: assigns |> Map.fetch!(:"$mfa") |> elem(0),
          name: name,
          params: Enum.map(args, &parse(&1, assigns))}
  end
  # annotated types can just be ignored
  def parse({:ann_type, _, [_type_annotation, type]}, assigns) do
    parse(type, assigns)
  end
  # default builtin
  def parse({:type, _, type, []}, _), do: builtin(type)
  def parse({:type, _, :bounded_fun, [fun, constraints]}, assigns) do
    # TODO: write a test against constraint assignment
    parse(fun, add_constraints(assigns, constraints))
  end

  defp match_mfa(%Type{module: m, name: f, params: p}, {m, f, a})
      when length(p) == a, do: true
  defp match_mfa(_, _), do: false

  defp add_constraints(assigns, []), do: assigns
  defp add_constraints(assigns, [constraint | rest]) do
    assigns
    |> add_constraint(constraint)
    |> add_constraints(rest)
  end

  defp add_constraint(assigns, {:type, _, :constraint,
                                [{:atom, _, :is_subtype},
                                [{:var, _, name}, type]]}) do
    Map.put(assigns, {name, :subtype_of}, parse(type, assigns))
  end
end
