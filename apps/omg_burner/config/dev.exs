use Mix.Config

config :omg_burner,
       casual_period: 10 * :math.pow(10, 3) |>  round,  # in milliseconds
       short_period: 1 * :math.pow(10, 3) |> round   # in milliseconds
