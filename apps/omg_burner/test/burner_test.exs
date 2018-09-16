defmodule OMG.BurnerTest do

  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner
  alias OMG.Burner.State

  @moduletag :integration

  @one_eth :math.pow(10, 18)
           |> round

  @timeout 20_000


  @zero_address OMG.API.Crypto.zero_address()

  setup() do
    OMG.Burner.State.start_link()
    OMG.Burner.Eth.start_link()
    :ok
  end

  defp deposit(value, from, contract) do
    {:ok, tx_hash} = OMG.Eth.RootChain.deposit(value, from, contract)
    {:ok, %{"status" => "0x1"}} = OMG.Eth.WaitFor.eth_receipt(tx_hash, @timeout)
    :ok
  end

#  @tag fixtures: [:authority, :root_chain, tx_opts]
#  test "start fee exit manually", %{authority: authority, root_chain: root_chain, tx_opts: opts} do
#
#    :ok = deposit(@one_eth, authority, root_chain)
#
#    OMG.Burner.accumulate_fees(ETH, @one_eth)
##    {:ok, tx_hash} = OMG.Burner.start_fee_exit(ETH, opts)
#
#    assert State.get_accumulated_fees(ETH) == 0
#
#  end

  #  test "start fee exit manually with invalid authority" do
  #
  #  end
  #
  #  test "start fee exit automatically" do
  #    # start server that takes care of starting exits automatically
  #
  #  end
  #
  #  test "deposit, report fees to the microservice, make an exchange - AKA happy path" do
  #
  #  end

end