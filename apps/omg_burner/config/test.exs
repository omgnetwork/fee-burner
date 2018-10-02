use Mix.Config

config :omg_burner,
       max_gas_price: :math.pow(10, 10)
                      |> round,
         # in gwei
       refresh_period: 500,
       casual_period: 2_000, # in milliseconds
       short_period: 2_000,
       thresholds: %{
         ETH => %{
           address: "0x00",
           decimals: 18,
           coinmarketcap_id: 1027,
           currency: USD,
           value: :math.pow(10, -9)
           # circa whole market is worth less than $1
         }
       }


