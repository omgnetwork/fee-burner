defmodule OMG.Burner.ThresholdAgent do
  use GenServer

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
      gas_expensive: true
    }

    GenServer.start_link(__MODULE__, state)

  end

  def init(state) do
    schedule_work(state)
    {:ok, state}
  end

  # handlers

  def handle_info(:loop, state) do
    state = do_work(state)
    schedule_work(state)
    {:noreply, state}
  end

  def handle_call({:get, setting}, _from, state) do
    {:reply, Map.get(state, setting), state}
  end

  def handle_call({:set, setting, value}, _from, state) do
    with {:ok, old} <- Map.fetch(state, setting)
      do
      new_state = state
                  |> Map.put(setting, value)
      {:reply, {:ok, old, value}, new_state}
    else
      _ -> {:reply, {:error, :no_such_setting}, state}
    end
  end

  # private

  defp schedule_work(state)do
    Process.send_after(self(), :loop, get_period(state))
    :ok
  end

  defp get_period(%{gas_expensive: false, casual: casual_period} = _state), do: casual_period
  defp get_period(%{gas_expensive: true, short: short_period} = _state), do: short_period

end