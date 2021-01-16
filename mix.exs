defmodule AbsintheExtra.MixProject do
  use Mix.Project

  def project do
    [
      app: :absinthe_extra,
      version: "0.0.1",
      deps: deps(),
      docs: [main: "AbsintheExtra", extras: ["README.md"]],
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "AbsintheExtra",
      source_url: "https://github.com/s-spica/absinthe_extra",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe, "~> 1.6"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:inch_ex, "~> 0.1", only: [:dev, :test], runtime: false}
    ]
  end
end
