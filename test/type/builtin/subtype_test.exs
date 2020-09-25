defmodule TypeTest.Builtin.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.List

  describe "builtin none" do
    test "is a subtype of itself" do
      assert builtin(:none) in builtin(:none)
    end

    test "is not a subtype of any" do
      refute builtin(:none) in builtin(:any)
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        refute builtin(:none) in target
      end)
    end
  end

  describe "builtin neg_integer" do
    test "is a subtype of itself" do
      assert builtin(:neg_integer) in builtin(:neg_integer)
    end

    test "is a subtype of integer and any" do
      assert builtin(:neg_integer) in builtin(:integer)
      assert builtin(:neg_integer) in builtin(:any)
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except([builtin(:neg_integer), builtin(:integer)])
      |> Enum.each(fn target ->
        refute builtin(:neg_integer) in target
      end)
    end
  end

  describe "builtin pos_integer" do
    test "is a subtype of itself" do
      assert builtin(:pos_integer) in builtin(:pos_integer)
    end

    test "is a subtype of integer and any" do
      assert builtin(:pos_integer) in builtin(:non_neg_integer)
      assert builtin(:pos_integer) in builtin(:integer)
      assert builtin(:pos_integer) in builtin(:any)
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except([builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer)])
      |> Enum.each(fn target ->
        refute builtin(:pos_integer) in target
      end)
    end
  end

  describe "builtin non_neg_integer" do
    test "is a subtype of itself" do
      assert builtin(:non_neg_integer) in builtin(:non_neg_integer)
    end

    test "is a subtype of integer and any" do
      assert builtin(:non_neg_integer) in builtin(:integer)
      assert builtin(:non_neg_integer) in builtin(:any)
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except([builtin(:non_neg_integer), builtin(:integer)])
      |> Enum.each(fn target ->
        refute builtin(:non_neg_integer) in target
      end)
    end
  end

  describe "builtin integer" do
    test "is a subtype of itself" do
      assert builtin(:integer) in builtin(:integer)
    end

    test "is a subtype of integer and any" do
      assert builtin(:integer) in builtin(:integer)
      assert builtin(:integer) in builtin(:any)
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([builtin(:integer)])
      |> Enum.each(fn target ->
        refute builtin(:integer) in target
      end)
    end
  end

  describe "builtin float" do
    test "is a subtype of itself" do
      assert builtin(:float) in builtin(:float)
    end

    test "is a subtype of integer and any" do
      assert builtin(:float) in builtin(:float)
      assert builtin(:float) in builtin(:any)
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([builtin(:float)])
      |> Enum.each(fn target ->
        refute builtin(:float) in target
      end)
    end
  end

  describe "builtin atom" do
    test "is a subtype of itself" do
      assert builtin(:atom) in builtin(:atom)
    end

    test "is a subtype of integer and any" do
      assert builtin(:atom) in builtin(:atom)
      assert builtin(:atom) in builtin(:any)
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([builtin(:atom)])
      |> Enum.each(fn target ->
        refute builtin(:atom) in target
      end)
    end
  end

  describe "builtin reference" do
    test "is a subtype of itself" do
      assert builtin(:reference) in builtin(:reference)
    end

    test "is a subtype of integer and any" do
      assert builtin(:reference) in builtin(:reference)
      assert builtin(:reference) in builtin(:any)
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([builtin(:reference)])
      |> Enum.each(fn target ->
        refute builtin(:reference) in target
      end)
    end
  end

  describe "builtin port" do
    test "is a subtype of itself" do
      assert builtin(:port) in builtin(:port)
    end

    test "is a subtype of integer and any" do
      assert builtin(:port) in builtin(:port)
      assert builtin(:port) in builtin(:any)
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([builtin(:port)])
      |> Enum.each(fn target ->
        refute builtin(:port) in target
      end)
    end
  end

  describe "builtin pid" do
    test "is a subtype of itself" do
      assert builtin(:pid) in builtin(:pid)
    end

    test "is a subtype of integer and any" do
      assert builtin(:pid) in builtin(:pid)
      assert builtin(:pid) in builtin(:any)
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([builtin(:pid)])
      |> Enum.each(fn target ->
        refute builtin(:pid) in target
      end)
    end
  end

  describe "builtin any" do
    test "is a subtype of itself" do
      assert builtin(:any) in builtin(:any)
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([builtin(:any)])
      |> Enum.each(fn target ->
        refute builtin(:any) in target
      end)
    end
  end
end
