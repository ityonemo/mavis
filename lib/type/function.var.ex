defmodule Type.Function.Var do

  @moduledoc """
  a special container type indicating that the function has a type dependency.

  ### Example:

  The following typespec:

  ```elixir
  @spec identity(x) :: x when x: var
  ```

  generates the following typespec:
  ```elixir
  %Type.Function{
    params: [%Type.Function.Var{name: :x}],
    return: %Type.Function.Var{name: :x}
  }
  ```

  if you further put a restriction on this typespec:

  ```elixir
  @spec identity(x) :: x when x: integer
  ```

  the `Type.Function.Var` will further exhibit the issued constraint:

  ```elixir
  %Type.Function{
    params: [%Type.Function.Var{name: :x, constraint: %Type{name: :integer}}],
    return: %Type.Function.Var{name: :x, constraint: %Type{name: :integer}}
  }
  ```
  """

  import Type, only: :macros
  @enforce_keys [:name]
  defstruct @enforce_keys ++ [constraint: any()]

  @type t :: %__MODULE__{
    name: atom,
    constraint: Type.t
  }

  @spec resolve(Type.t, %{t => Type.t}) :: Type.t
  @doc false
  def resolve(type, map) when is_map_key(map, type) do
    Type.intersection(type.constraint, map[type])
  end
  def resolve(t = %Type.Map{required: rmap, optional: omap}, map) do
    %{t | required: Enum.map(rmap, &resolve(&1, map)),
          optional: Enum.map(omap, &resolve(&1, map))}
  end
  def resolve(t = %Type.NonemptyList{type: type, final: final}, map) do
    %{t | type: Enum.map(type, &resolve(&1, map)), final: resolve(final, map)}
  end
  def resolve(t = %Type.Union{of: types}, map) do
    %{t | of: Enum.map(types, &resolve(&1, map))}
  end
  def resolve(t = %Type.Tuple{elements: elements}, map) do
    %{t | elements: Enum.map(elements, &resolve(&1, map))}
  end
  def resolve({k, v}, map) do
    {resolve(k, map), resolve(v, map)}
  end
  def resolve(type, _map), do: type
end

defimpl Inspect, for: Type.Function.Var do
  import Type, only: :macros
  import Inspect.Algebra

  def inspect(var, opts = %{custom_options: [show_constraints: true]}) do
    case var.constraint do
      any() -> "#{var.name}: var"
      _ ->
        clean_opts = %{opts | custom_options: []}
        concat("#{var.name}: ", to_doc(var.constraint, clean_opts))
    end
  end
  def inspect(var, _opts) do
    "#{var.name}"
  end
end

defimpl Type.Properties, for: Type.Function.Var do

  alias Type.Function.Var

  def typegroup(%{constraint: constraint}) do
    Type.typegroup(constraint)
  end

  def compare(lhs, rhs = %Var{}) do
    case Type.compare(lhs.constraint, rhs.constraint) do
      comp when comp != :eq -> comp
      :eq -> Type.compare(lhs.name, rhs.name)
    end
  end

  def compare(%{constraint: constraint}, rhs) do
    case Type.compare(constraint, rhs) do
      :eq -> :lt
      comp -> comp
    end
  end

  import Type, only: :macros
  import Type.Helpers

  intersection do
    def intersection(_, %Var{}) do
      raise "can't intersect two var types"
    end

    def intersection(left = %Var{}, right) do
      case Type.intersection(left.constraint, right) do
        none() -> none()
        type -> %{left | constraint: type}
      end
    end
  end

  subtype do
    def subtype?(left, right = %Var{}) do
      Type.subtype?(left.constraint, right.constraint)
    end
    def subtype?(left = %{}, right) do
      Type.subtype?(left.constraint, right)
    end
  end

  usable_as do
    def usable_as(%Var{}, _right, _meta) do
      raise "unreachable"
    end
  end

  def normalize(type), do: type
end
