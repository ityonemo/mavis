defmodule Type.Union do
  defstruct [of: []]
  @type t :: %__MODULE__{of: [Type.t]}

  def of(%Type.Union{of: of1}, %Type.Union{of: of2}) do
    collapse(%Type.Union{of: of1 ++ of2})
  end

  def of(%Type.Union{of: of}, t) do
    collapse(%Type.Union{of: [t | of]})
  end

  def of(t, %Type.Union{of: of}) do
    collapse(%Type.Union{of: [t | of]})
  end

  def of(t1, t2) do
    collapse(%Type.Union{of: [t1, t2]})
  end

  # for now.  TODO: we need more sophisticated checking on this.
  def collapse(%__MODULE__{of: lst}) do
    %__MODULE__{of: lst |> Enum.uniq |> Enum.sort}
  end

  defimpl Type.Typed do
    import Type, only: :macros

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(_, _), do: :type_error
  end

  defimpl Collectable do
    alias Type.Union

    def into(original) do
      collector_fun = fn
        # starting with an empty union results in
        %Union{of: lst}, {:cont, elem} -> %Union{of: [elem | lst]}
        %Union{of: []}, :done -> %Type{name: :none}
        %Union{of: [one]}, :done -> one
        union = %Union{}, :done -> Union.collapse(union)
        _set, :halt -> :ok
      end

      {original, collector_fun}
    end
  end
end
