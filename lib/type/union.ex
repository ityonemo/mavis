defmodule Type.Union do
  @enforce_keys [:of]
  defstruct @enforce_keys

  @type t :: %__MODULE__{of: [Type.t]}

  def of(%Type.Union{of: of1}, %Type.Union{of: of2}) do
    %Type.Union{of: collapse(of1 ++ of2)}
  end

  def of(%Type.Union{of: of}, t) do
    %Type.Union{of: collapse([t | of])}
  end

  def of(t, %Type.Union{of: of}) do
    %Type.Union{of: collapse([t | of])}
  end

  def of(t1, t2) do
    %Type.Union{of: collapse([t1, t2])}
  end

  # for now.  TODO: we need more sophisticated checking on this.
  def collapse(lst) do
    lst |> Enum.uniq |> Enum.sort
  end

  defimpl Type.Typed do
    import Type

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(_, _), do: :type_error
  end
end
