defmodule OMG.Burner.HttpRequester do

  @gas_station_url "https://ethgasstation.info/json/ethgasAPI.json"
  @market_api_url "https://api.coinmarketcap.com/v2/"


  def get_gas_price(json) do
    price = Poison.decode!(json)
    |> Map.get("safeLowWait")

    case price do
      nil -> :error
      price -> {:ok, price}
    end
  end

  def get_token_price(json, currency) do

    currency_string = currency
                      |> Atom.to_string()
                      |> String.trim_leading("Elixir.")

    price = Poison.decode!(json)
            |> Map.get("data")
            |> Map.get("quotes")
            |> Map.get(currency_string)
            |> Map.get("price")

    case price do
      nil -> :error
      price -> {:ok, price}
    end

  end

end