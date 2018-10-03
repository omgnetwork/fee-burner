defmodule OMG.BurnerTest do

  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner
  alias OMG.Burner.State

  @moduletag :integration

  @timeout 20_000
  @one_eth :math.pow(10, 18)
           |> round

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

  @tag fixtures: [:authority, :root_chain, :tx_opts]
  test "start fee exit manually", %{authority: authority, root_chain: root_chain, tx_opts: opts} do

    :ok = deposit(@one_eth, authority, root_chain)

    OMG.Burner.accumulate_fees(ETH, @one_eth)
    {:ok, tx_hash} = OMG.Burner.start_fee_exit(ETH, opts)

    assert State.get_accumulated_fees(ETH) == {:error, :no_such_record}
    assert State.get_pending_fees(ETH) == {:ok, @one_eth, tx_hash}

    :ok = Burner.confirm_pending_exit_start(ETH)

    assert State.get_accumulated_fees(ETH) == {:error, :no_such_record}
    assert State.get_pending_fees(ETH) == {:error, :no_such_record}

  end

  @tag fixtures: [:authority, :root_chain]
  test "deposit, report fees to the microservice, make an exchange - AKA happy path",
       %{authority: authority, root_chain: root_chain} do

    OMG.Burner.Eth.set(:authority, authority)
    OMG.Burner.Eth.set(:contract, root_chain)

    OMG.Burner.ThresholdAgent.start_link() # TODO: move

    :ok = deposit(@one_eth, authority, root_chain)
    OMG.Burner.accumulate_fees(ETH, @one_eth)

    # sleep for 10 seconds so background threads can start fee exit automatically
    # also wait for a transaction to be mined and confirmed
    :timer.sleep(10_000)

    assert State.get_accumulated_fees(ETH) == {:error, :no_such_record}
    assert State.get_pending_fees(ETH) == {:error, :no_such_record}

  end
end

# TODO: add clean-ups
# TODO: gas price is a of magnitude to high