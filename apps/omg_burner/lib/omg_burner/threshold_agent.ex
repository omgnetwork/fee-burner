defmodule OMG.Burner.ThresholdAgent do
  use GenServer
  alias OMG.Burner.HttpRequester, as: Requester

  def get(setting) do

  end

  def set(setting, value) do

  end

  # GenServer

  def start_link(options) do

    casual_period = options.casual_period || Application.get_env(:omg_burner, :casual_period)
    short_period = options.short_period || Application.get_env(:omg_burner, :short_period) || casual_period
    max_gas_price = options.max_gas_price || Application.get_env(:omg_burmer, :max_gas_price)

    state = %{
      casual: casual_period,
      short: short_period,
      max_gas_price: max_gas_price,
      active_period: casual_period
    }

    GenServer.start_link(__MODULE__, state)

  end

  def init(state) do
    schedule_work(state)
    {:ok, state}
  end

  # handlers

  def handle_info(:loop, state) do
    new_state = state
                |> do_work()
                |> schedule_work()
    {:noreply, new_state}
  end

  def handle_call({:get, setting}, _from, state) do
    {:reply, Map.get(state, setting), state}
  end

  def handle_call({:set, setting, value}, _from, state) do
    with {:ok, old} <- Map.fetch(state, setting)
      do
      upated_state = state
                     |> Map.put(setting, value)
    else
      _ -> {:reply, {:error, :no_such_setting}, state}
    end
  end

  # private

  defp schedule_work(state) do
    Process.send_after(self(), :loop, state.active_period)
    :ok
  end

  defp do_work(state) do
    with :ok <- check_gas_price(state) do
      check_thresholds()
      state
    else
      :error -> Map.put(state, :active_period, state.short_period)
    end
  end

  defp check_gas_price(%{max_gas_price: max_gas_price} = state) do
    with {:ok, current_price} <- Requester.get_gas_price(),
         true <- current_price <= max_gas_price
      do
      :ok
    else
      :error -> Logger.error("A problem with gas station occured. Check connection or API changes")
                :error
      false -> Logger.info("Gas price exceeds maximum value")
               :error
    end
  end

  defp check_thresholds() do
    # TODO
  end

end