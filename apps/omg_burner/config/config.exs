use Mix.Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $message\n",
  metadata: [:module, :function, :request_id]

config :ethereumex,
  scheme: "http",
  host: "localhost",
  port: 8545,
  url: "http://localhost:8545",
  request_timeout: :infinity,
  http_options: [
    recv_timeout: :infinity
  ]

config :omg_burner,
  # in wei
  max_gas_price: (30 * :math.pow(10, 9)) |> round,
  max_checks: 10000,
  refresh_period: :math.pow(10, 3) |> round,
  # in milliseconds
  casual_period: (60 * :math.pow(10, 3)) |> round,
  # in milliseconds
  short_period: (10 * :math.pow(10, 3)) |> round,
  thresholds: %{
    ETH => %{
      address: "0x00",
      decimals: 18,
      coinmarketcap_id: 1027,
      currency: USD,
      value: 100
    }
  }

import_config "./#{Mix.env()}.exs"
