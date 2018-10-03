defmodule OMG.Burner.HttpRequesterTest do
  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner.HttpRequester, as: Requester

  @eth_id 1027

  @tag fixtures: [:gasstation_response]
  test "decode gas_price from gas station's response", %{gasstation_response: response} do
    expected_price = (2.8 * :math.pow(10, 9)) |> round

    assert Requester.decode_gas_price(response) == {:ok, expected_price}
  end

  @tag fixtures: [:coinmarketcap_response]
  test "decode token's price from response", %{coinmarketcap_response: response} do
    assert Requester.decode_token_price(response, USD) == {:ok, 7032.1841007}
    assert Requester.decode_token_price(response, EUR) == {:ok, 6065.1814328287}
  end

  @tag :integration
  test "get gas price from ethgasstation" do
    HTTPoison.start()
    {:ok, _} = Requester.get_gas_price()
  end

  @tag :integration
  test "get token price from coinmarketcap" do
    HTTPoison.start()
    {:ok, _} = Requester.get_token_price(@eth_id, USD)
    {:ok, _} = Requester.get_token_price(@eth_id, EUR)
    {:ok, 1.0} = Requester.get_token_price(@eth_id, ETH)
  end
end
