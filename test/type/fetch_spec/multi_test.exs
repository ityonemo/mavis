defmodule TypeTest.Type.FetchSpec.MultiTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.SpecCase

  @moduletag :fetch

  @source TypeTest.SpecExample.Multi

  test "literal atoms" do
    assert {:ok, identity_for(builtin(:integer)) <|>
                 identity_for(builtin(:atom))} ==
      Type.fetch_spec(@source, :multi, 1)
  end
end
