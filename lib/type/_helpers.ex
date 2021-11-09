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

  @doc """
  Wraps the `Type.Algebra.usable_as/3` function headers in common prologue and
  fallback clauses.  This prevents errors from being made in code that must be common to all types.

  Prologue function matches:
  - matches equal types and makes them output :ok
  - matches usable_as with `any()` and makes them output :ok

  Fallback function matches:
  - catches usable_as against unions; and performs the appropriate attempt to
    match into each of the union's subtypes.
  - catches all other attempts to run usable_as, and returns `{:error, metadata}`
  """
  defmacro usable_as(do: block) do
    quote do
      def usable_as(type, type, _meta), do: :ok

      if __MODULE__ == Type.Algebra.Type do
      def usable_as(none(), target, meta) do
        {:error, Type.Message.make(none(), target, meta)}
      end
      end

      def usable_as(type, Type.any(), meta), do: :ok

      def usable_as(challenge, target = %Type.Function.Var{}, meta) do
        Type.usable_as(challenge, target.constraint, meta)
      end

      def usable_as(challenge, target = %Type.Opaque{}, meta) do
        case Type.usable_as(challenge, target.type) do
          :ok -> {:maybe, [Type.Message.make(challenge, target, meta)]}
          usable -> usable
        end
      end

      unquote(block)

      def usable_as(challenge, target, meta) when is_remote(target) do
        Type.usable_as(challenge, Type.fetch_type!(target))
      end

      # some integer types override the union analysis, so this must
      # come at the end.
      def usable_as(challenge, target = %Type.Union{of: types}, meta) do
        types
        |> Enum.map(&Type.usable_as(challenge, &1, meta))
        |> Enum.reduce(&Type.ternary_or/2)
        |> case do
          {:error, msg} -> {:error, %{msg | type: challenge, target: target}}
          any -> any
        end
      end

      def usable_as(challenge, union, meta) do
        {:error, Type.Message.make(challenge, union, meta)}
      end
    end
  end

  @doc """
  Wraps the `Type.Algebra.intersection/2` function headers in a common prologue.
  This prevents errors from being made in code that must be common to all types.

  Prologue function matches:
  - matches itself and returns itself
  - matches `t:any/0` and returns itself
  - calculates intersections for remote types
  - intersects union types
  - intersects function var types
  """
  defmacro intersection(do: block) do
    quote do
      @spec intersection(Type.t, Type.t) :: Type.t
      def intersection(type, type), do: type
      def intersection(type, any()), do: type

      if __MODULE__ == Type.Algebra.Type do
      def intersection(any(), type) do
        type
      end
      end

      unless __MODULE__ == Type.Algebra.Type.Union do
      def intersection(type, union = %Type.Union{}) do
        Type.intersection(union, type)
      end
      end

      unless __MODULE__ == Type.Algebra.Type.Function.Var do
      def intersection(left, right = %Type.Function.Var{}) do
        case Type.intersection(left, right.constraint) do
          none() -> none()
          type -> %{right | constraint: type}
        end
      end
      end

      unquote(block)

      def intersection(left, right) when is_remote(right) do
        # special case.
        Type.intersection(left, Type.fetch_type!(right))
      end

      def intersection(_, _), do: none()
    end
  end

  @doc """
  Wraps the `c:Type.Helpers.group_compare/2` function headers in a common prologue.
  This prevents errors from being made in code that must be common to all types.

  Prologue function matches:
  - matches identical types and reports equality
  - matches `t:String.t/0` special case (only for `Type.Bitstring`)
  - compares union types and puts them in
  - compares opaque types
  - compares function var types
  """
  defmacro group_compare(do: block) do
    quote do
      def group_compare(type, type), do: :eq

      def group_compare(type, var = %Type.Function.Var{}) do
        case group_compare(type, var.constraint) do
          :eq -> :gt
          cmp -> cmp
        end
      end

      def group_compare(type1, %Type.Opaque{type: type2}) do
        case group_compare(type1, type2) do
          :eq -> :gt
          cmp -> cmp
        end
      end

      def group_compare(type1, %Type.Union{of: [type2 | _]}) do
        case group_compare(type1, type2) do
          :gt -> :gt
          _ -> :lt
        end
      end

      unquote(block)
    end
  end

  @doc """
  Wraps the `Type.Algebra.subtype?/2` function headers in a common prologue.
  This prevents errors from being made in code that must be common to all types.

  Prologue function matches:
  - matches itself and returns true
  - matches `t:none/0` and returns false
  - matches `t:any/0` and returns any
  - calculates intersections for remote types
  - intersects union types
  - intersects function var types

  can also take `:usable_as` as an argument; this declares that `subtype?/2` is
  equivalent to an `:ok` response from `Type.usable_as/3`.
  """
  defmacro subtype(do: block) do

    might_be_union = Enum.map(
      [Union, Function.Var, nil],
      &Module.concat(Type.Algebra.Type, &1))

    quote do
      def subtype?(a, a), do: true

      unless __MODULE__ in unquote(might_be_union) do
        def subtype?(a, %Type.Union{of: types}) do
          Enum.any?(types, &Type.subtype?(a, &1))
        end
      end

      if __MODULE__ == Type.Algebra.Type do
        def subtype?(none(), _), do: false
      end

      def subtype?(_, any()), do: true

      unquote(block)

      def subtype?(left, right) when is_remote(right) do
        r_solved = Type.fetch_type!(right)
        if left == r_solved do
          false
        else
          subtype?(left, r_solved)
        end
      end
      def subtype?(left, %Type.Function.Var{constraint: c}) do
        subtype?(left, c)
      end
      def subtype?(_, _), do: false
    end
  end
  defmacro subtype(:usable_as) do
    quote do
      def subtype?(left, right) when is_remote(right) do
        r_solved = Type.fetch_type!(right)
        if left == r_solved do
          false
        else
          subtype?(left, r_solved)
        end
      end
      def subtype?(a, %Type.Function.Var{constraint: c}) do
        subtype?(a, c)
      end

      unless __MODULE__ == Type.Algebra.Range do
        def subtype?(a, %Type.Union{of: types}) do
          Enum.any?(types, &Type.subtype?(a, &1))
        end
      end

      def subtype?(a, b), do: usable_as(a, b, []) == :ok
    end
  end

  defmacro subtract(do: block) do
    quote do
      def subtract(type, type), do: none()
      def subtract(type, any()), do: none()
      def subtract(base, %Type.Union{of: types}) do
        Enum.reduce(types, base, &Type.subtract(&2, &1))
      end
      unquote(block)
      def subtract(ltype, rtype) do
        case Type.intersection(ltype, rtype) do
          ^ltype -> none()
          none() -> ltype
          type -> %Type.Subtraction{base: ltype, exclude: type}
        end
      end
    end
  end

  @doc false
  def lexical_compare(left = %{module: m, name: n}, right) do
    with {:m, ^m} <- {:m, right.module},
         {:n, ^n} <- {:n, right.name} do
      left.params
      |> Enum.zip(right.params)
      |> Enum.each(fn {l, r} ->
        comp = Type.compare(l, r)
        unless comp == :eq do
          throw comp
        end
      end)
      raise "unreachable"
    else
      {:m, _} -> if m > right.module, do: :gt, else: :lt
      {:n, _} -> if n > right.name, do: :gt, else: :lt
    end
  catch
    :gt -> :gt
    :lt -> :lt
  end
end
