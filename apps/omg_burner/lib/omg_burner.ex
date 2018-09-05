defmodule OMG.Burner do
  use GenServer

  # API
  def add_fee_to_be_collected(token, value) do
  end

  def start_fee_exit(token) do

  end

  def confirm_fee_exit_started(token) do

  end

  # GenServer
  def start_link()do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do

  end

  # handlers


end
