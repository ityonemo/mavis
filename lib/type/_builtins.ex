defmodule Type.Builtins do
  @moduledoc false

  # helper module providing a DSL for making basic and builtin types.

  #@primitive_builtins ~w(none neg_integer pos_integer float node module
  #atom reference port pid iolist any)a
#
  #@doc false
  #def primitive_builtins, do: @primitive_builtins
#
  #@composite_builtins ~w(term integer non_neg_integer tuple arity byte
  #map binary bitstring boolean char charlist nonempty_charlist fun
  #function identifier iodata keyword list nonempty_list
  #maybe_improper_list nonempty_maybe_improper_list mfa no_return number
  #struct timeout)a
#
  #@doc false
  #def composite_builtins, do: @composite_builtins
#
  #@builtins @primitive_builtins ++ @composite_builtins
  #@doc false
  #def builtins, do: @builtins

  defmacro defbuiltin(do: code) do
    builtin_fn = quote unquote: false do
      # do stuff here:
      basics = Module.get_attribute(__MODULE__, :basic, %{})
      builtins = __MODULE__
      |> Module.get_attribute(:builtin, %{})
      |> Map.merge(basics)

      for {k, v} <- builtins do
        def builtin(unquote(k)) do
          unquote(v)
        end
      end

      def builtins(), do: unquote(Map.keys(builtins))
    end

    quote do
      unquote(code)
      unquote(builtin_fn)
    end
  end

  @doc false
  defmacro basic(name) do
    type_ast = Macro.escape(
      {:%{}, [line: __CALLER__.line], [__struct__: Type, module: nil, name: name, params: []]}
    )

    if name == :node do
      # the node type doesn't get a macro, because this overloads Kernel.node/0
      # should use type(node()) instead.
      quote do
        basics = Module.get_attribute(__MODULE__, :basic, %{})
        Module.put_attribute(__MODULE__, :basic, Map.put(basics, unquote(name), unquote(type_ast)))
      end
    else
      quote do
        basics = Module.get_attribute(__MODULE__, :basic, %{})
        Module.put_attribute(__MODULE__, :basic, Map.put(basics, unquote(name), unquote(type_ast)))

        @doc """
        provides the `#{unquote(name)}()` primitive type.

        ### Example:
        ```elixir
        iex> import Type, only: :macros
        iex> #{unquote(name)}()
        %Type{name: #{inspect(unquote(name))}}
        ```

        *Usable in matches*
        """
        @doc type: true
        defmacro unquote(name)(), do: unquote(type_ast)
      end
    end
  end

  @doc false
  defmacro builtin(name, ast, test) do
    type_ast = Macro.escape(ast)
    quote do
      basics = Module.get_attribute(__MODULE__, :builtin, %{})
      Module.put_attribute(__MODULE__, :builtin, Map.put(basics, unquote(name), unquote(type_ast)))

      @doc """
      provides the `#{unquote(name)}()` primitive type.

      ### Example:
      ```elixir
      iex> import Type, only: :macros
      iex> #{unquote(name)}()
      #{unquote(test)}
      ```

      *Usable in matches*
      """
      @doc type: true
      defmacro unquote(name)(), do: unquote(type_ast)
    end
  end
end
