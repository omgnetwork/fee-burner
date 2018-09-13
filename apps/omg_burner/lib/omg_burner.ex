defmodule OMG.Burner do
  require Logger

  alias OMG.Burner.State
  alias OMG.Burner.Eth

  # API
  def add_fee_to_be_collected(token, value) do
    State.add_fee(token, value)
  end

  def start_fee_exit(token) do
    {:ok, value} = State.preexit_token(token)

    Logger.info("Starting #{token} exit, have accumulated #{value} of tokens")
    Eth.start_fee_exit(token, value)

  end

  def confirm_fee_exit_started(token) do
    :ok = State.confirm_token_exited(token)
    Logger.info("Confirmed token (#{token}})stared exit")
  end

  def cancel_token_exit(token) do
    :ok = State.cancel_preexit(token)
    Logger.info("Canceled token (#{token}}) exit")
  end

end
