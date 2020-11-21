defmodule Mavis.MixProject do
  use Mix.Project

  @source_url "https://github.com/ityonemo/mavis"
  @version "0.0.5"

  def project do
    [
      app: :mavis,
      version: @version,
      elixir: "~> 1.10",
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs()
    ]
  end

  def application, do: []

  defp elixirc_paths(:test), do: ["lib", "test/_support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      description: "Type system tools for elixir",
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.2", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test},
      {:stream_data, "~> 0.5.0", only: :test}
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

  defp docs do
    [
      main: "Type",
      source_ref: @version,
      source_url: @source_url,
      groups_for_modules: [
        Types: [
          Type.AsBoolean,
          Type.Bitstring,
          Type.Function,
          Type.Function.Var,
          Type.List,
          Type.Map,
          Type.Opaque,
          Type.Tuple,
          Type.Union
        ]
      ],
      groups_for_functions: [
        Guards: &(&1[:guards]),
        "Type Macros": &(&1[:type])
      ],
      extras: [
        "CHANGELOG.md"
      ]
    ]
  end
end
