defmodule AdjustableServer do

  defmacro __using__(_opts)do
    quote do
      use GenServer

      def get(setting) do
        GenServer.call(__MODULE__, {:get, setting})
      end

      def set(setting, value) do
        GenServer.call(__MODULE__, {:set, setting, value})
      end

      def handle_call({:get, setting}, _from, state) do
        {:reply, Map.fetch(state, setting), state}
      end

      def handle_call({:set, setting, value}, _from, state) do
        with {:ok, old} <- Map.fetch(state, setting)
          do
          upated_state = Map.put(state, setting, value)
          {:reply, {:ok, old}, upated_state}
        else
          _ -> {:reply, {:error, :no_such_setting}, state}
        end
      end
    end
  end

end