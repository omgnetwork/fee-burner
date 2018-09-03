defmodule OMG.BurnerTest do

  use ExUnitFixtures
  use ExUnit.Case

  @tag fixtures: [:omg_contract]
  test "start fee exit", %{omg_contract: omg} do
    assert :ok == omg
  end

end
