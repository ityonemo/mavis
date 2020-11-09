# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

defmodule Type.Helpers do
  #######################################################################
  ## boilerplate for preventing mistakes

  @group_for %{
    "Integer" => 1,
    "Range" => 1,
    "Atom" => 3,
    "Function" => 5,
    "Tuple" => 8,
    "Map" => 9,
    "List" => 10,
    "Bitstring" => 11
  }

  @doc """
  Type modules should implement this function to perform comparisons against
  all other types in their type group.

  See `Type.typegroup/1`
  """
  @callback group_compare(Type.t, Type.t) :: :lt | :gt | :eq

  # exists to prevent mistakes when generating functions.
  defmacro __using__(_) do
    group = __CALLER__.module
    |> Module.split
    |> List.last
    |> :erlang.map_get(@group_for)

    quote bind_quoted: [group: group] do
      @behaviour Type.Helpers

      import Type.Helpers

      @group group
      def typegroup(_), do: @group

      def compare(this, other) do
        other_group = Type.typegroup(other)
        cond do
          @group > other_group -> :gt
          @group < other_group -> :lt
          true ->
            group_compare(this, other)
        end
      end
    end
  end

  @doc """
  Wraps the `Type.Properties.usable_as/3` function headers in common prologue and
  fallback clauses.  This prevents errors from being made in code that must be common to all types.

  Prologue function matches:
  - matches equal types and makes them output :ok
  - matches usable_as with `builtin(:any)` and makes them output :ok

  Fallback function matches:
  - catches usable_as against unions; and performs the appropriate attempt to
    match into each of the union's subtypes.
  - catches all other attempts to run usable_as, and returns `{:error, metadata}`
  """
  defmacro usable_as(do: block) do
    quote do
      def usable_as(type, type, meta), do: :ok

      if __MODULE__ == Type.Properties.Type do
      def usable_as(builtin(:none), target, meta) do
        {:error, Type.Message.make(builtin(:none), target, meta)}
      end
      end

      def usable_as(type, Type.builtin(:any), meta), do: :ok

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
  Wraps the `Type.Properties.intersection/2` function headers in a common prologue.
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
      def intersection(type, builtin(:any)), do: type

      if __MODULE__ == Type.Properties.Type do
      def intersection(builtin(:any), type) do
        type
      end
      end

      unless __MODULE__ == Type.Properties.Type.Union do
      def intersection(type, union = %Type.Union{}) do
        Type.intersection(union, type)
      end
      end

      unless __MODULE__ == Type.Properties.Type.Function.Var do
      def intersection(left, right = %Type.Function.Var{}) do
        case Type.intersection(left, right.constraint) do
          builtin(:none) -> builtin(:none)
          type -> %{right | constraint: type}
        end
      end
      end

      unquote(block)

      def intersection(left, right) when is_remote(right) do
        # special case.
        Type.intersection(left, Type.fetch_type!(right))
      end

      def intersection(_, _), do: builtin(:none)
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

      def group_compare(type1, %Type.Union{of: [type2 | _]}) do
        case group_compare(type1, type2) do
          :gt -> :gt
          _ -> :lt
        end
      end

      def group_compare(type1, %Type.Opaque{type: type2}) do
        case group_compare(type1, type2) do
          :eq -> :gt
          cmp -> cmp
        end
      end

      def group_compare(type, var = %Type.Function.Var{}) do
        case group_compare(type, var.constraint) do
          :eq -> :gt
          cmp -> cmp
        end
      end

      unquote(block)
    end
  end

  @doc """
  Wraps the `Type.Properties.subtype?/2` function headers in a common prologue.
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
    # TODO: figure out how to DRY this.
    quote do
      def subtype?(a, a), do: true

      unless __MODULE__ in [Type.Properties.Type.Union] do
        def subtype?(a, %Type.Union{of: types}) do
          Enum.any?(types, &Type.subtype?(a, &1))
        end
      end

      if __MODULE__ == Type.Properties.Type do
        def subtype?(builtin(:none), _), do: false
      end

      def subtype?(_, builtin(:any)), do: true

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

      unless __MODULE__ == Type.Properties.Range do
        def subtype?(a, %Type.Union{of: types}) do
          Enum.any?(types, &Type.subtype?(a, &1))
        end
      end

      def subtype?(a, b), do: usable_as(a, b, []) == :ok
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
