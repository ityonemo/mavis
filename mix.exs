defmodule Mavis.MixProject do
  use Mix.Project

  def project do
    [
      app: :mavis,
      version: "0.0.1",
      elixir: "~> 1.10",
      test_coverage: [tool: ExCoveralls],
      package: [
        description: "type system tools for elixir",
        licenses: ["MIT"],
        files: ~w(lib .formatter.exs mix.exs README* LICENSE* VERSIONS*),
        links: %{"GitHub" => "https://github.com/ityonemo/mavis"}
      ],
      source_url: "https://github.com/ityonemo/state_server/",
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: [
        main: "Type",
        groups_for_modules: [
          "Types": [Type.AsBoolean, Type.Bitstring, Type.Function,
          Type.Function.Var, Type.List, Type.Map, Type.Opaque, Type.Tuple,
          Type.Union]
        ]
      ]
    ]
  end

  def application, do: []

  defp elixirc_paths(:test), do: ["lib", "test/_support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps, do: [
    {:credo, "~> 1.2", only: [:test, :dev], runtime: false},
    {:ex_doc, "~> 0.23", only: :dev, runtime: :false},
    {:excoveralls, "~> 0.11.1", only: :test}
  ]

end
