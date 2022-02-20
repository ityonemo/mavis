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
    Type.Function.Branch => 5,
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
    disable_branch_comparison = unless __CALLER__.module == Type.Algebra.Type.Function.Branch do
      quote do
        def compare(_, %{__struct__: Type.Function.Branch}), do: raise "function branches are not comparable"
      end
    end

    quote do
      unquote(disable_branch_comparison)
      def compare(same, same), do: :eq
      def compare(_, %Type{module: nil, name: :any}), do: :lt
      def compare(ltype, rtype) do
        lgroup = typegroup(ltype)
        rgroup = Type.typegroup(rtype)
        case {lgroup, rgroup, ltype, rtype} do
          {lgroup, rgroup, _, _} when lgroup < rgroup -> :lt
          {lgroup, rgroup, _, _} when lgroup > rgroup -> :gt
          {_, _, %Type.Union{}, _} ->
            unquote(module).unquote(call)(ltype, rtype)
          {_, _, _, %Type.Union{of: [first | _]}} ->
            result = Type.compare(ltype, first)
            if result == :eq, do: :lt, else: result
          _ ->
            unquote(module).unquote(call)(ltype, rtype)
        end
      end
    end
  end

  defmacro algebra_merge_fun(module, call \\ :merge) do
    generics_clause = if __CALLER__.module == Type.Algebra.Type do
      quote do
        def merge(%Type{module: nil, name: :none, params: []}, type), do: {:merge, [type]}
        def merge(%Type{module: nil, name: :any, params: []}, type), do: {:merge, [%Type{name: :any}]}
      end
    end

    quote do
      unquote(generics_clause)
      def merge(type, type), do: {:merge, [type]}
      def merge(type, %Type{module: nil, name: :any, params: []}), do: {:merge, [%Type{name: :any}]}
      def merge(type, %Type{module: nil, name: :none, params: []}), do: {:merge, [type]}
      def merge(_, %Type.Union{}), do: raise "can't merge with unions"
      def merge(ltype, rtype) do
        lgroup = typegroup(ltype)
        rgroup = Type.typegroup(rtype)
        cond do
          lgroup != rgroup -> :nomerge
          Type.compare(ltype, rtype) == :gt ->
            unquote(module).unquote(call)(ltype, rtype)
          true ->
            Type.merge(rtype, ltype)
        end
      end
    end
  end

  defmacro algebra_intersection_fun(module, call \\ :intersect) do
    unions_clause = if __CALLER__.module == Type.Algebra.Type.Union do
      quote do
        def intersect(lunion, runion) do
          Type.Union.intersect(lunion, runion)
        end
      end
    else
      quote do
        def intersect(ltype, rtype = %Type.Union{}) do
          Type.intersect(rtype, ltype)
        end
        def intersect(ltype, rtype) do
          case Type.compare(ltype, rtype) do
            :gt ->
              unquote(module).unquote(call)(ltype, rtype)
            :lt ->
              Type.intersect(rtype, ltype)
            :eq -> ltype
          end
        end
      end
    end

    quote do
      def intersect(ltype, %Type{module: nil, name: :any}), do: ltype
      def intersect(type, type), do: type
      unquote(unions_clause)
    end
  end

  defmacro algebra_subtype_fun(module, call \\ :subtype?) do
    quote do
      def subtype?(type, type), do: true
      def subtype?(type, %Type{module: nil, name: :any, params: []}), do: true
      def subtype?(ltype, rtype), do: unquote(module).unquote(call)(ltype, rtype)
    end
  end

  defmacro algebra_usable_as_fun(module, call \\ :usable_as) do
    main_clause = if __CALLER__.module == Type.Algebra.Type.Union do
      quote do
        def usable_as(ltype, rtype, meta) do
          unquote(module).unquote(call)(ltype, rtype, meta)
        end
      end
    else
      quote do
        def usable_as(challenge, target = %Type.Union{of: union}, meta) do
          alias Type.Message
          case Type.partition(challenge, union) do
            [] -> {:error, Message.make(challenge, target, meta)}
            partitioned ->
              partitioned
              |> Enum.flat_map(fn partition ->
                Enum.map(union, &Type.usable_as(partition, &1, meta))
              end)
              |> Enum.reduce(&Type.ternary_or/2)
              |> case do
                :ok ->
                  if Type.union(partitioned) == challenge do
                    :ok
                  else
                    {:maybe, [Message.make(challenge, target, meta)]}
                  end
                msg -> Message._rebrand(msg, challenge, target)
              end
          end
        end
        def usable_as(challenge, target, meta) do
          cg = Type.typegroup(challenge)
          tg = Type.typegroup(target)
          if cg == 12 or cg == tg do
          # TODO: switch implementation to commented out impl when any() becomes a union.
          #if Type.typegroup(challenge) == Type.typegroup(target) do
            unquote(module).unquote(call)(challenge, target, meta)
          else
            {:error, Type.Message.make(challenge, target, meta)}
          end
        end
      end
    end

    quote do
      def usable_as(type, type, _meta), do: :ok
      def usable_as(a, %Type{module: nil, name: :none, params: []}, meta) do
        {:error, Type.Message.make(a, %Type{name: :none}, meta)}
      end
      def usable_as(_, %Type{module: nil, name: :any, params: []}, _meta), do: :ok
      unquote(main_clause)
    end
  end

  defmacro __using__(opts) do
    module = __CALLER__.module

    quote bind_quoted: [module: module, default_subtype: opts[:default_subtype]] do
      alias Type.Helpers
      import Helpers
      @behaviour Helpers
      Helpers.typegroup_fun()

      if default_subtype do
        def subtype?(type, maybe_supertype) do
          usable_as(type, maybe_supertype, []) == :ok
        end
      end

      defimpl Type.Algebra do
        defdelegate typegroup(type), to: module

        import Helpers
        Helpers.algebra_compare_fun(unquote(module))
        Helpers.algebra_merge_fun(unquote(module))
        Helpers.algebra_intersection_fun(unquote(module))
        Helpers.algebra_usable_as_fun(unquote(module))

        defdelegate usable_as(subject, target, meta), to: module
        defdelegate subtype?(subject, target), to: module
        defdelegate subtract(ltype, rtype), to: module
        defdelegate normalize(type), to: module
      end
    end
  end
end
