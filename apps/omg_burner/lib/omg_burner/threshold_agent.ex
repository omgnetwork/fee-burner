defmodule OMG.Burner.ThresholdAgent do

  use AdjustableServer

  alias OMG.Burner.HttpRequester, as: Requester
  alias OMG.Burner.State
  require Logger

  def start_link(args \\ %{}) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # GenServer
  def init(args) do

    casual_period = Map.get(args, :casual_period) || Application.get_env(:omg_burner, :casual_period)
    short_period = Map.get(args, :short_period) || Application.get_env(:omg_burner, :short_period) || casual_period
    max_gas_price = Map.get(args, :max_gas_price) || Application.get_env(:omg_burner, :max_gas_price)

    state = %{
      casual_period: casual_period,
      short_period: short_period,
      max_gas_price: max_gas_price,
      active_period: casual_period
    }

    schedule_work(state)
    {:ok, state}
  end

  # handlers

  def handle_info(:loop, state) do
    new_state = state
                |> do_work()
    schedule_work(new_state)
    {:noreply, new_state}
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
         true <- current_price <= max_gas_price do

      Logger.info("Current gas price: #{current_price}")
      :ok

    else
      :error -> Logger.error("A problem with gas station occured. Check connection or API changes")
                :error
      false -> Logger.info("Gas price exceeds maximum value")
               :error
    end
  end

  defp check_thresholds() do

    preexited_tokens = State.get_preexited_fees()
                       |> Map.keys()
    accumulated_tokens = State.get_accumulated_fees()
                         |> Map.keys()

    tokens_to_check = accumulated_tokens -- preexited_tokens

    Enum.each(tokens_to_check, &check_threshold/1)

  end

  defp check_threshold(token) do
    threshold_info = Application.get_env(:omg_burner, :threshold)
                     |> Map.get(token)
    with :ready <- do_check_threshold(token, threshold_info) do
      OMG.Burner.start_fee_exit(token)
    else
      :unsupported_token -> Logger.error("Missing configuration for #{token}")
    end
    :ok
  end

  defp do_check_threshold(token, nil), do: :unsupported_token
  defp do_check_threshold(token, info) do
    token_id = Map.fetch!(info, :coinmarketcap_id)
    decimals = Map.fetch!(info, :decimals)
    currency = Map.fetch!(info, :currency)
    threshold_value = Map.fetch!(info, :value)

    price = Requester.get_token_price(token_id, currency)

    accumualted = State.get_accumulated_fees(token)

    check_ready(accumualted, price, threshold_value, decimals)

  end

  defp check_ready(accumulated, price, threshold, decimals) do

    case (accumulated / :math.pow(10, decimals)) * price >= threshold do
      true -> :ready
      false -> :not_ready
    end
  end

end