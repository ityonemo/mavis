defmodule TypeTest.InspectCase do
  # `import TypeTest.InspectCase`

  def inspect_type(module, name) do
    {:ok, type} = Type.fetch_type(module, name)
    inspect type
  end
end
