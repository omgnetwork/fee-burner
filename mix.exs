defmodule OMG.FeeBurner.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [
        test: ["test --no-start"]
      ]
    ]
  end

  defp deps do
    [
      # NOTE: we're overriding for the sake of `omg_api` mix.exs deps. Otherwise the override is ignored
      # TODO: removing the override is advised, but it gives undefined symbol errors, see
      #       https://github.com/exthereum/exth_crypto/issues/8#issuecomment-416227176
      #      {:libsecp256k1, "~> 0.1.4", compile: "${HOME}/.mix/rebar compile", override: true}
      {
        :ex_unit_fixtures,
        git: "https://github.com/omisego/ex_unit_fixtures.git", branch: "feature/require_files_not_load", only: [:test]
      }
    ]
  end
end
