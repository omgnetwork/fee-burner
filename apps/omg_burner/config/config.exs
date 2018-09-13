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
# TODO : add missing configs
config :omg_burner,
       max_gas_price:  30, # in gwei
       casual_period: 60 * :math.pow(10, 3) |>  round,  # in milliseconds
       short_period: 10 * :math.pow(10, 3) |> round,   # in milliseconds
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
