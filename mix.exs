defmodule Mavis.MixProject do
  use Mix.Project

  def project do
    [
      app: :mavis,
      version: "0.1.0",
      elixir: "~> 1.10",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application, do: []

  defp elixirc_paths(:test), do: ["lib", "test/_support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps, do: [
    {:credo, "~> 1.2", only: [:test, :dev], runtime: false},
    {:ex_doc, "~> 0.21.2", only: :dev, runtime: :false},
    {:excoveralls, "~> 0.11.1", only: :test}
  ]

end
