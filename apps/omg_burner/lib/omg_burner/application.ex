defmodule OMG.Burner.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      OMG.Burner.State,
      OMG.Burner.Eth,
      OMG.Burner.ThresholdAgent
    ]

    opts = [strategy: :one_for_all]

    Supervisor.start_link(children, opts)
  end
end
