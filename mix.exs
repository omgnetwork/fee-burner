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
      {
        :ex_unit_fixtures,
        git: "https://github.com/omisego/ex_unit_fixtures.git", branch: "feature/require_files_not_load", only: [:test]
      }
    ]
  end
end
