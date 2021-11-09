defmodule Type.Helpers do
  @typegroups %{
    Type.Integer => 1,
    Integer => 1,
    Range => 1,
    Type.Float => 2,
    Float => 2,
    Type.Atom => 3,
    Atom => 3,
    Type.Function => 5,
    Type.Tuple => 8,
    Type.Map => 9,
    Type.List => 10,
    List => 10,
    Type.Bitstring => 11,
    BitString => 11,
  }

  defmacro typegroup_fun() do
    module = __CALLER__.module
    cond do
      typegroup = @typegroups[module] ->
        quote do
          def typegroup(_), do: unquote(typegroup)
        end
      typegroup = @typegroups[get_algebra(module)] ->
        quote do
          def typegroup(_), do: unquote(typegroup)
        end
      true -> nil
    end
  end

  defp get_algebra(module) do
    case Module.split(module) do
      ["Type", "Algebra" | rest] ->
        Module.concat(rest)
      _ -> nil
    end
  end

  defmacro algebra_compare_fun(module, call \\ :compare) do
    quote do
      def compare(same, same), do: :eq
      def compare(_, %Type{module: nil, name: :any}), do: :lt
      def compare(ltype, rtype) do
        lgroup = typegroup(ltype)
        rgroup = Type.typegroup(rtype)
        cond do
          lgroup < rgroup -> :lt
          lgroup > rgroup -> :gt
          match?(%Type.Union{}, rtype) ->
            %{of: [first | _]} = rtype
            result = Type.compare(ltype, first)
            if result == :eq, do: :lt, else: result
          true ->
            unquote(module).unquote(call)(ltype, rtype)
        end
      end
    end
  end

  defmacro algebra_intersection_fun(module, call \\ :intersection) do
    unions_clause = if __CALLER__.module == Type.Algebra.Type.Union do
      quote do
        def intersection(lunion, runion) do
          Type.Union.intersection(lunion, runion)
        end
      end
    else
      quote do
        def intersection(ltype, rtype = %Type.Union{}) do
          Type.intersection(rtype, ltype)
        end
        def intersection(ltype, rtype) do
          #IO.puts("===========================================")
          #ltype |> IO.inspect(label: "74", structs: false)
          #rtype |> IO.inspect(label: "75", structs: false)
          #unquote(module) |> IO.inspect(label: "80")
          #unquote(call) |> IO.inspect(label: "81")
          case Type.compare(ltype, rtype) do # |> IO.inspect(label: "76") do
            :gt ->
              unquote(module).unquote(call)(ltype, rtype)
            :lt ->
              #raise "foo"
              Type.intersection(rtype, ltype)
            :eq -> ltype
          end
        end
      end
    end

    quote do
      def intersection(ltype, %Type{module: nil, name: :any}), do: ltype
      def intersection(type, type), do: type
      unquote(unions_clause)
    end
  end

  defmacro algebra_subtype_fun(module, call \\ :subtype?) do
    quote do
      def subtype?(type, type), do: true
      def subtype?(ltype, rtype), do: unquote(module).unquote(call)(ltype, rtype)
    end
  end

  defmacro __using__(_opts) do
    module = __CALLER__.module
    quote bind_quoted: [module: module] do
      alias Type.Helpers
      import Helpers
      @behaviour Helpers
      Helpers.typegroup_fun()

      defimpl Type.Algebra do
        defdelegate typegroup(type), to: module

        import Helpers
        Helpers.algebra_compare_fun(unquote(module))
        Helpers.algebra_intersection_fun(unquote(module))

        defdelegate usable_as(subject, target, meta), to: module
        defdelegate subtype?(subject, target), to: module
        defdelegate subtract(ltype, rtype), to: module
        defdelegate normalize(type), to: module
      end
    end
  end
end
