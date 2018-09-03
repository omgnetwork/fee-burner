defmodule OMG.Burner do

  @type address :: <<_ :: 160>>
  @type tx_hash :: integer()

  def start_fee_exit(_token, _amount, _gas_price, _from, _contract \\ nil) do
    :ok
  end

end
