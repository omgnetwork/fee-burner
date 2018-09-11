use Mix.Config

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
       contract_address: "0x0",
       max_gas_price:  30, # in gwei
       casual_period: 60 * :math.pow(10, 3) |>  round,  # in milliseconds
       short_period: 10 * :math.pow(10, 3) |> round,   # in milliseconds
       thresholds: %{
         "0x00" => %{
           # "0x00" for Ether
           coinmarketcap_id: 1027,
           currency: USD,
           value: 100
         }
       }


import_config "./#{Mix.env()}.exs"
