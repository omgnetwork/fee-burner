defmodule OMG.Burner.HttpRequester do

  @gas_station_url "https://ethgasstation.info/json/ethgasAPI.json"
  @market_api_url "https://api.coinmarketcap.com/v2/ticker/"

  def get_gas_price() do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(@gas_station_url) do
      decode_gas_price(body)
    else
      _ -> :error
    end
  end

  def get_token_price(id, currency) do

    currency = get_currency_string(currency)
    request = @market_api_url <> "#{id}/?convert=#{currency}"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(request)
      do
      decode_token_price(body, currency)
    else
      _ -> :error
    end
  end

  def decode_token_price(json, currency) when is_atom(currency) do
    currency = get_currency_string(currency)
    decode_token_price(json, currency)
  end

  def decode_token_price(json, currency) do
    price = Poison.decode!(json)
            |> Map.get("data")
            |> Map.get("quotes")
            |> Map.get(currency)
            |> Map.get("price")

    case price do
      nil -> :error
      price -> {:ok, price}
    end

  end

  def decode_gas_price(json) do
    price = Poison.decode!(json)
            |> Map.get("safeLow")

    case price do
      nil -> :error
      price -> {:ok, price * :math.pow(10, 8) |> round } # ethgasstation API returns price in tenth of gwei (look at the bottom)
    end
  end

  defp get_currency_string(currency) when is_atom(currency) do
    currency
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
  end
end


# more here: https://www.reddit.com/r/ethdev/comments/8bktt6/why_is_ethgasstation_reporting_recommended_gas