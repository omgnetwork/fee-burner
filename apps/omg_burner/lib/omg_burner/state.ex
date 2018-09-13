defmodule OMG.Burner.State do

  @type token_t() :: atom()
  @type error_t() :: {:error, atom()}
  @type status_t() :: :ok | error_t()
  @type status_with_value_t :: {:ok, number()} | error_t()

  @type accumulated_values_t() :: %{token_t() => number()}
  @type state_t() :: {accumulated_values_t(), accumulated_values_t()}

  require Logger

  use GenServer

  # API
  def start_link(initial_state \\ {%{}, %{}}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @spec add_fee(token_t(), number()) :: status_t()
  def add_fee(token, value) when is_atom(token) and is_number(value) do
    GenServer.cast(__MODULE__, {:add_fee, token, value})
    :ok
  end

  @spec preexit_token(token_t()) :: status_with_value_t()
  def preexit_token(token) when is_atom(token) do
    GenServer.call(__MODULE__, {:preexit, token})
  end

  @spec confirm_token_exited(token_t()) :: status_t()
  def confirm_token_exited(token) when is_atom(token) do
    GenServer.call(__MODULE__, {:confirm_exit, token})
  end

  @spec cancel_preexit(token_t()) :: status_t()
  def cancel_preexit(token) when is_atom(token) do
    GenServer.call(__MODULE__, {:cancel_exit, token})
  end

  @spec get_preexited_fees(token_t) :: number()
  def get_preexited_fees(token) when is_atom(token) do
    GenServer.call(__MODULE__, {:get_preexited, token})
  end

  @spec get_accumulated_fees(token_t()) :: number()
  def get_accumulated_fees(token) when is_atom(token) do
    GenServer.call(__MODULE__, {:get_accumulated, token})
  end

  def get_accumualted_fees() do
    GenServer.call(__MODULE__, :get_accumulated)
  end

  def get_preexited_fees(token) when is_atom(token) do
    GenServer.call(__MODULE__,:get_preexited)
  end

  # GenServer

  def init({_accumulated, _preexited} = state) do
    {:ok, state}
  end

  def handle_cast({:add_fee, token, value}, {accumulated, preexited} = _state) do

    new_accumulated = do_add_fee(token, value, accumulated)
    new_state = {new_accumulated, preexited}

    {:noreply, new_state}

  end

  def handle_call({:preexit, token}, _from, state) do
    {reply, new_state} = do_preexit(token, state)
    {:reply, reply, new_state}
  end

  def handle_call({:get_accumulated, token}, _from, {accumulated, _} = state) do
    {:reply, Map.get(accumulated, token, 0), state}
  end

  def handle_call(:get_accumulated, _from, {accumulated, _} = state) do
    {:reply, accumulated, state}
  end

  def handle_call({:get_preexited, token}, _from, {_, preexited} = state) do
    {:reply, Map.get(preexited, token, 0), state}
  end

  def handle_call(:get_preexited, _from, {_, preexited} = state) do
    {:reply, preexited, state}
  end

  def handle_call({:confirm_exit, token}, _from, {accumulated, preexited}) do
    {reply, new_preexited} = do_confirm_exit(token, preexited)
    {:reply, reply, {accumulated, new_preexited}}
  end

  def handle_call({:cancel_exit, token}, _from, state) do
    {reply, new_state} = do_cancel_exit(token, state)
    {:reply, reply, new_state}
  end

  # TODO: leave it ?
  #  def handle_cast(_, _, state) do
  #    {:noreply, state}
  #  end
  #
  #  def handle_call(_, _from, state) do
  #    {:reply, :error, state}
  #  end

  defp do_add_fee(token, value, accumulated) do
    tmp = accumulated
          |> Map.update(token, value, &(&1 + value))

    # todo: move
    if Map.get(tmp, token) > 0 do
      tmp
    else
      Map.delete(tmp, token)
    end
  end

  defp do_preexit(token, {accumulated, preexited} = state) do
    with :error <- Map.fetch(preexited, token),
         {:ok, value} <- Map.fetch(accumulated, token),
         true <- value > 0 do
      {{:ok, value}, move_to_preexited(token, state)}
    else
      {:ok, value} -> {{:error, :already_preexited}, state}
      _ -> {{:error, :nothing_to_preexit}, state}
    end
  end

  defp move_to_preexited(token, {accumulated, preexited}) do
    {to_preexit, new_accumulated} = Map.pop(accumulated, token)
    new_preexited = Map.put_new(preexited, token, to_preexit)
    {new_accumulated, new_preexited}
  end

  defp do_confirm_exit(token, preexited) do
    case Map.fetch(preexited, token) do
      {:ok, _} -> {:ok, Map.delete(preexited, token)}
      _ -> {{:error, :nothing_to_confirm}, preexited}
    end
  end

  defp do_cancel_exit(token, {accumulated, preexited} = state) do
    case Map.fetch(preexited, token) do
      {:ok, value} -> {:ok, {do_add_fee(token, value, accumulated), Map.delete(preexited, token)}}
      _ -> {{:error, :nothing_to_cancel}, state}
    end
  end

end