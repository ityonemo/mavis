defmodule Type.Spec do

  @moduledoc false

  import Type, only: :macros

  @builtins Type.builtins()

  def parse(spec, assigns \\ %{})

  # fix assigns
  def parse({:var, _, name}, assigns) when is_map_key(assigns, name) do
    assigns[name]
  end
  def parse({:var, _, :_}, _assigns) do
    any()
  end
  def parse({:var, _, name}, assigns) when is_map_key(assigns, {name, :subtype_of}) do
    %Type.Function.Var{name: name, constraint: assigns[{name, :subtype_of}]}
  end
  def parse({:var, _, name}, _assigns) do
    %Type.Function.Var{name: name}
  end

  # general types
  def parse({:type, _, :range, [first, last]}, assigns), do: parse(first, assigns)..parse(last, assigns)
  def parse({:op, _, :-, value}, assigns), do: -parse(value, assigns)
  def parse({:integer, _, value}, _), do: value
  def parse({:atom, _, value}, _), do: value
  def parse({:type, _, :fun, [{:type, _, :any}, return]}, assigns) do
    %Type.Function{params: :any, return: parse(return, assigns)}
  end
  def parse({:type, _, :fun, [{:type, _, :product, params}, return]}, assigns) do
    param_types = Enum.map(params, &parse(&1, assigns))
    %Type.Function{params: param_types, return: parse(return, assigns)}
  end

  def parse({:type, _, :map, :any}, _assigns), do: map()
  def parse({:type, _, :map, params}, assigns) when is_list(params) do
    Enum.reduce(params, %Type.Map{}, fn
      {:type, _, :map_field_assoc, [src_type, dst_type]}, map = %{optional: optional} ->
        %{map | optional: Map.put(optional, parse(src_type, assigns), parse(dst_type, assigns))}
      {:type, _, :map_field_exact, [src_type = {t, _, _}, dst_type]}, map = %{required: required}
        when t in [:atom, :integer] ->
        %{map | required: Map.put(required, parse(src_type, assigns), parse(dst_type, assigns))}
      # downgrade required types that aren't either integer or atom literals.
      {:type, _, :map_field_exact, [src_type, dst_type]}, map = %{optional: optional} ->
        %{map | optional: Map.put(optional, parse(src_type, assigns), parse(dst_type, assigns))}
    end)
  end

  def parse({:type, _, :tuple, :any}, _), do: tuple()
  def parse({:type, _, :tuple, elements}, assigns) do
    %Type.Tuple{elements: Enum.map(elements, &parse(&1, assigns))}
  end
  # empty list
  def parse({:type, _, nil, []}, _), do: []
  # overrides
  def parse({:type, _, :list, [type]}, assigns) do
    list(parse(type, assigns))
  end
  def parse({:type, _, :nonempty_list, [type]}, assigns) do
    %Type.NonemptyList{type: parse(type, assigns)}
  end
  def parse({:type, _, :maybe_improper_list, [type, final]}, assigns) do
    %Type.Union{of: [
      %Type.NonemptyList{ type: parse(type, assigns), final: Type.union(parse(final, assigns), [])},
      []]}
  end
  def parse({:type, _, :nonempty_improper_list, [type, final]}, assigns) do
    %Type.NonemptyList{
      type: parse(type, assigns),
      final: parse(final, assigns)}
  end
  def parse({:type, _, :nonempty_maybe_improper_list, [type, final]}, assigns) do
    %Type.NonemptyList{
      type: parse(type, assigns),
      final: Type.union(parse(final, assigns), [])}
  end
  def parse({:type, _, :binary, [size, unit]}, assigns) do
    %Type.Bitstring{size: parse(size, assigns), unit: parse(unit, assigns)}
  end
  def parse({:type, _, :union, types}, assigns) do
    types
    |> Enum.map(&parse(&1, assigns))
    |> Enum.into(%Type.Union{})
  end
  # overridden remote types
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :charlist}, []]}, _) do
    list(0..0x10FFFF)
  end
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :nonempty_charlist}, []]}, _) do
    list(0..0x10FFFF, ...)
  end
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, []]}, _) do
    list(tuple({atom(), any()}))
  end
  def parse({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, [type]]}, assigns) do
    list(tuple({atom(), parse(type, assigns)}))
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
  # type annotations can just be ignored
  def parse({:ann_type, _, [_type_annotation, type]}, assigns) do
    parse(type, assigns)
  end
  # default builtin
  def parse({:type, _, type, []}, _) when type in [:node | @builtins] do
    Type.builtin(type)
  end
  def parse({:type, _, :bounded_fun, [fun, constraints]}, assigns) do
    # TODO: write a test against constraint assignment
    parse(fun, add_constraints(assigns, constraints))
  end

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
