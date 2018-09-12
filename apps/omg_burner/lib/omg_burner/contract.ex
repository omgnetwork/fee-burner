defmodule OMG.Burner.Eth do

  use AdjustableServer
  alias OmiseGO.Eth

  @success "0x01"
  @failure "0x00"

  def start_link(args \\ nil) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    timeout = Map.get(args, :timeout) || Application.get_env(:omg_burner, :timeout)
    contract_addr = Map.get(args, :contract_addr) || Application.get_env(:omg_burner, :contract_addr)


    # refresh period
    # authority
    # how many refreshes
    state = %{

    }

  end

  def start_fee_exit(token, amount, gas_price) when is_atom(token)do
    GenServer.cast(__MODULE__, {:start, token, amount, gas_price})
  end

  def handle_cast({:start, token, amount, gas_price}, state) do

    refresh_period = Map.get(state, :refresh_period)
    authority = Map.get(state, :authority)

    case Eth.start_fee_exit(token, amount, gas_price, authority) do
      {:ok, tx_hash} -> Process.send_after(self(), {:wait, tx_hash, token, 0}, refresh_period)
      _ -> Logger.error("Could not send transaction. Authority: #{authority}, token: #{token}, amount: #{amount}")
    end
    {:noreply, state}
  end

  def handle_info({:wait, tx_hash, token, count}, state) do
    max_count = Map.get(state, :max_count)
    do_handle_wait(tx_hash, token, count, max_count)
    {:noreply, state}
  end

  defp do_handle_wait(_, _, count, max_count) when count > max_count do
    #todo: send cancel
  end

  defp do_handle_wait(tx_hash, token, count, _)do
    case Ethereumex.HttpClient.eth_get_transaction_receipt(txhash) do
      {:ok, receipt} when receipt != nil -> :ok
      # todo: check receipt
      _ -> Process.send_after(self(), {:wait, tx_hash, count + 1})
    end
    :ok
  end

  defp process_receipt(%{status: status} = receipt, token) when status == @failure,
       do: OMG.Burner.cancel_token_exit(token)
  defp process_receipt(%{status: status} = receipt, token) when status == @success,
       do: OMG.Burner.confirm_fee_exit_started(token)

end