defmodule OmisegoFeeBurner.MixProject do
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

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:omisego_omisego, git: "git@github.com:omisego/omisego.git", branch: "develop"}
    ]
  end
end
