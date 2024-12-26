defmodule MiniD3fl.MixProject do
  use Mix.Project

  def project do
    [
      app: :mini_d3fl,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :observer, :wx, :runtime_tools, :tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:axon, "~> 0.6", github:  "elixir-nx/axon"},
      {:polaris, "~> 0.1"},
      {:exla, "~> 0.6", github:  "elixir-nx/exla", sparse:  "exla", override: true},
      {:nx, "~> 0.6", github:  "elixir-nx/nx", sparse:  "nx", override:  true},
      {:scidata, "~> 0.1.11"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
