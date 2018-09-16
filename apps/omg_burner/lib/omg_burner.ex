defmodule OMG.Burner do
  require Logger

  alias OMG.Burner.State
  alias OMG.Burner.Eth

  @type token :: atom
  @type tx_hash :: String.t
  @type tx_option :: {:gas_price, pos_integer} | {:from, String.t} | {:contract, String.t}
  @type error :: {:error, atom}

  #TODO: use value instead of amount

  ### API ###
  @spec accumulate_fees(token, integer) :: :ok
  def accumulate_fees(token, value) do
    :ok = State.add_fee(token, value)
  end

  @spec start_fee_exit(token, [tx_option]) :: {:ok, tx_hash} | error
  def start_fee_exit(token, opts \\ []) do
    {:ok, value} = State.move_to_pending(token)
    Eth.start_fee_exit(token, value, opts)
    |> build_info(token, value)
    |> handle_sent_transaction()
  end

  @spec confirm_pending_exit_start(token) :: :ok | error
  def confirm_pending_exit_start(token) do
    :ok = State.confirm_pending(token)
    :ok = Logger.info("Confirmed stared exit: #{token}")
    :ok
  end

  @spec cancel_pending_exit_start(token) :: :ok | error
  def cancel_pending_exit_start(token) do
    :ok = State.cancel_pending(token)
    Logger.info("Canceled token exit: #{token}")
  end

  ### PRIVATE ###

  defp handle_sent_transaction([:ok | info]) do
    {:token, token} = Enum.at(info, 0)
    {:tx_hash, tx_hash} = Enum.at(info, 2)
    :ok = State.set_tx_hash_of_pending(token, tx_hash)
    :ok = Logger.info("Transaction to start exit was succesfully sent: #{inspect info}")
    {:ok, tx_hash}
  end

  defp handle_sent_transaction([:error | info]) do
    {:token, token} = Enum.at(info, 0)
    {:error, error} = Enum.at(info, 2)
    :ok = State.cancel_pending(token)
    :ok = Logger.error("Sending transaction failed: #{inspect info}")
    {:error, error}
  end

  defp build_info({:ok, tx_hash}, token, value), do: [:ok, token: token, value: value, tx_hash: tx_hash]
  defp build_info({:error, reason}, token, value), do: [:error, token: token, value: value, error: reason]

end
