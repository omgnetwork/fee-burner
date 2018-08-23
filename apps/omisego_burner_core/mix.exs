defmodule OmiseGO.BurnerCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :omisego_burner_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      load_paths: ["deps/libsecp256k1/_build/#{Mix.env()}/libsecp256k1/ebin"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OmiseGO.BurnerCore.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libsecp256k1, "~> 0.1.9", compile: "make && mix deps.get && mix compile", app: false, override: true},
      {:elixir_omg, git: "git@github.com:pik694/elixir-omg.git", branch: "tmp"}
    ]
  end
end
