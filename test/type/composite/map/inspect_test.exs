defmodule TypeTest.Map.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect
  @moduletag :map

  pull_types(defmodule Maps do
    defstruct [:atom]

    @type empty :: %{}
    @type atom_key :: %{atom: atom}
    @type required_integer :: %{0 => atom}
    @type optional_literal :: %{optional(:atom) => atom}
    @type struct_literal :: %__MODULE__{}
    @type struct_defined_literal :: %__MODULE__{atom: atom}
    @type ordering :: %{optional(:foo) => :bar, 0 => :bar, baz: :bar}
  end)

  describe "the empty map type" do
    test "looks like itself" do
      assert "type(%{})" == inspect(@empty)
    end

    test "code translates correctly" do
      assert @empty == eval_inspect(@empty)
    end
  end

  describe "the atom key map" do
    test "looks like itself" do
      assert "type(%{atom: atom()})" == inspect(@atom_key)
    end

    test "code translates correctly" do
      assert @atom_key == eval_inspect(@atom_key)
    end
  end

  describe "the required integer map" do
    test "looks like itself" do
      assert "type(%{0 => atom()})" == inspect(@required_integer)
    end

    test "code translates correctly" do
      assert @required_integer == eval_inspect(@required_integer)
    end
  end

  describe "the optional literal map" do
    test "looks like itself" do
      assert "type(%{optional(:atom) => atom()})" == inspect(@optional_literal)
    end

    test "code translates correctly" do
      assert @optional_literal == eval_inspect(@optional_literal)
    end
  end

  describe "the struct_literal map" do
    test "looks like itself" do
      assert "type(%#{inspect Maps}{})" == inspect(@struct_literal)
    end

    test "code translates correctly" do
      assert @struct_literal == eval_inspect(@struct_literal)
    end
  end

  describe "the struct_defined_literal map" do
    test "looks like itself" do
      assert "type(%#{inspect Maps}{atom: atom()})" == inspect(@struct_defined_literal)
    end

    test "code translates correctly" do
      assert @struct_defined_literal == eval_inspect(@struct_defined_literal)
    end
  end

  describe "the map with a strange order" do
    test "looks like itself" do
      assert "type(%{optional(:foo) => :bar, 0 => :bar, baz: :bar})" == inspect(@ordering)
    end

    test "code translates correctly" do
      assert @ordering == eval_inspect(@ordering)
    end
  end
end
