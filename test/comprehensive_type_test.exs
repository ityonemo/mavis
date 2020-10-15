defmodule TypeTest.ComprehensiveTypeTest do
  use ExUnit.Case, async: true

  # tests that mavis understands all standard library types successfully

  import Type, only: :macros

  @elixir_modules Enum.map(~w(Kernel Kernel.SpecialForms Atom Base Bitwise Date
  DateTime Exception Float Function Integer Module NaiveDateTime Record
  Regex String Time Tuple URI Version Version.Requirement Access Date.Range
  Enum Keyword List Map MapSet Range Stream File File.Stat File.Stream
  IO.Stream OptionParser Path Port StringIO System Calendar Calendar.ISO
  Calendar.TimeZoneDatabase Calendar.UTCOnlyTimeZoneDatabase Agent Application
  Config Config.Provider Config.Reader DynamicSupervisor GenServer Node Process
  Registry Supervisor Task Task.Supervisor Collectable Enumerable Inspect
  Inspect.Algebra Inspect.Opts List.Chars Protocol String.Chars Code
  Kernel.ParallelCompiler Macro.Env), &Module.concat(Elixir, &1))


  test "all types" do
    Enum.each(@elixir_modules, fn module ->
      case Code.Typespec.fetch_types(module) do
        {:ok, types} ->
          types
          |> Enum.map(&strip_type_name/1)
          |> Enum.map(&do_fetch_type(module, &1))
        :error -> raise "can't fetch types from #{module}"
      end
    end)
  end

  @types ~w(type typep opaque)a

  defp strip_type_name({t, {name, _, []}}) when t in @types do
    name
  end
  defp strip_type_name({t, {name, _, lst}}) when t in @types do
    {name, Enum.map(1..length(lst), fn _ -> builtin(:any) end)}
  end

  defp do_fetch_type(module, {name, params}) do
    Type.fetch_type(module, name, params)
  end
  defp do_fetch_type(module, name) do
    Type.fetch_type(module, name)
  end

  test "all specs" do
    Enum.each(@elixir_modules, fn module ->
      Enum.each(module.module_info[:exports], &do_fetch_spec(module, &1))
    end)
  end

  defp do_fetch_spec(module, {fun, arity}) do
    module |> IO.inspect(label: "55")
    fun |> IO.inspect(label: "56")
    arity |> IO.inspect(label: "57")
    Type.fetch_spec(module, fun, arity)
  end

end
