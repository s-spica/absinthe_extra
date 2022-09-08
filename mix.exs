defmodule AbsintheExtra.MixProject do
  use Mix.Project

  def project do
    [
      app: :absinthe_extra,
      version: "0.1.14",
      deps: deps(),
      docs: [main: "readme", extras: ["README.md"]],
      description: description(),
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "AbsintheExtra",
      source_url: "https://github.com/s-spica/absinthe_extra",
      homepage_url: "https://github.com/s-spica/absinthe_extra",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp description do
    "AbsintheExtra is a extra tool for absinthe"
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      name: "absinthe_extra",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/s-spica/absinthe_extra"}
    ]
  end

  defp deps do
    [
      {:absinthe, "~> 1.6"},
      {:absinthe_relay, "~> 1.5.0"},
      {:absinthe_phoenix, "~> 2.0"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:inch_ex, "~> 0.1", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.6"}
    ]
  end
end
