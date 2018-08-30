defmodule OMG.BurnerCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :omg_burner_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      load_paths: ["deps/libsecp256k1/_build/#{Mix.env()}/libsecp256k1/ebin"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OMG.BurnerCore.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libsecp256k1, "~> 0.1.9", compile: "make && mix deps.get && mix compile", app: false, override: true},
      {
        :plasma_contracts,
        git: "https://github.com/pik694/plasma-contracts",
        branch: "feature/fee-burner",
        sparse: "contracts/",
        compile: compile_plasma_contracts(),
        app: false,
        override: true,
        only: [:dev, :test]
      },

      {:elixir_omg, git: "git@github.com:pik694/elixir-omg.git", branch: "feature/fee-burner"},
      {
        :exw3,
        git: "git@github.com:omisego/exw3.git",
        branch: "error_messages"
      },
      {
        :fee_burner_contracts,
        path: "../../contracts",
        compile: compile_fee_burner_contracts(),
        app: false,
        only: [:dev, :test]
      },
      {
        :ethereumex,
        env: :prod,
        git: "https://github.com/omisego/ethereumex.git",
        branch: "request_timeout",
        override: true
      },
      {
        :abi,
        env: :prod,
        git: "https://github.com/omisego/abi.git",
        branch: "encode_dynamic_types",
        override: true
      },
      {:omisego,
        path: "../../contracts",
        compile: copy_omisego_contract,
        app: false,
        only: [:dev, :test]
      }


    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "test/support"]

  defp compile_plasma_contracts do
    mixfile_path = File.cwd!()
    "cd #{mixfile_path}/../../ && py-solc-simple -i deps/plasma_contracts/contracts/ -o contracts/build/"
  end

  defp compile_fee_burner_contracts do
    mixfile_path = File.cwd!()
    "cd #{mixfile_path}/../../ && py-solc-simple -i contracts/ -o contracts/build/"
  end

  defp copy_omisego_contract do
    mixfile_path = File.cwd!()
    "cd #{mixfile_path}/../../ && cp ./contracts/OmiseGO.json ./contracts/build/"
  end

end
