defmodule OMG.Burner.HttpRequesterTest do

  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner.HttpRequester, as: Requester

  @tag fixtures: [:gasstation_response]
  test "get gas_price from gasstation's response", %{gasstation_response: response} do

    assert Requester.get_gas_price(response) == {:ok, 2.6}

  end

  @tag fixtures: [:coinmarketcap_response]
  test "get token's price from response", %{coinmarketcap_response: response} do

    assert Requester.get_token_price(response, USD) == {:ok, 7032.1841007}
    assert Requester.get_token_price(response, EUR) == {:ok, 6065.1814328287}

  end

end