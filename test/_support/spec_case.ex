defmodule TypeTest.SpecCase do
  # `import TypeTest.SpecCase`
  alias Type.Function

  @spec identity_for(Type.t) :: Function.t
  def identity_for(type) do
    %Function{params: [type], return: type}
  end
end
