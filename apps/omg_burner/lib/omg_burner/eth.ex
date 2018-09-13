defmodule OMG.Burner.Eth do

  require Logger

  use AdjustableServer
  alias OMG.Eth

  @success "0x01"
  @failure "0x00"

  def start_link(args \\ nil) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    refresh_period = Map.get(args, :refresh_period) || Application.get_env(:omg_burner, :short_period)
    max_checks = Map.get(args, :max_checks) || Application.get_env(:omg_burner, :max_checks)
    authority = Map.get(args, :authority) || Application.get_env(:omg_burner, :authority)

    state = %{
      max_checks: max_checks,
      authority: authority,
      refresh_period: refresh_period
    }

    {:ok, state}

  end

  def start_fee_exit(token, amount, gas_price) when is_atom(token)do
    GenServer.cast(__MODULE__, {:start, token, amount, gas_price})
  end

  def handle_cast({:start, token, amount, gas_price}, state) do

    refresh_period = Map.get(state, :refresh_period)
    authority = Map.get(state, :authority)

    token_address = Application.get_env(:omg_burner, :thresholds)
                    |> Map.fetch!(token)
                    |> Map.fetch!(:address)

    case Eth.start_fee_exit(token_address, amount, gas_price, authority) do
      {:ok, tx_hash} -> Process.send_after(self(), {:wait, tx_hash, token, 0}, refresh_period)
      _ -> Logger.error("Could not send transaction. Authority: #{authority}, token: #{token}, amount: #{amount}")
    end
    {:noreply, state}
  end

  def handle_info({:wait, tx_hash, token, count}, state) do
    max_count = Map.get(state, :max_checks)
    refresh_period = Map.get(state, :refresh_period)
    do_handle_wait(tx_hash, token, count, max_count, refresh_period)
    {:noreply, state}
  end

  defp do_handle_wait(_, token, count, max_count, _) when count > max_count, do: OMG.Burner.cancel_token_exit(token)

  defp do_handle_wait(tx_hash, token, count, _, refresh_period)do
    case Ethereumex.HttpClient.eth_get_transaction_receipt(tx_hash) do
      {:ok, receipt} when receipt != nil -> process_receipt(receipt, token)
      _ -> Process.send_after(self(), {:wait, tx_hash, count + 1}, refresh_period)
    end
    :ok
  end

  defp process_receipt(%{status: status} = _receipt, token) when status == @failure,
       do: OMG.Burner.cancel_token_exit(token)
  defp process_receipt(%{status: status} = _receipt, token) when status == @success,
       do: OMG.Burner.confirm_fee_exit_started(token)

end