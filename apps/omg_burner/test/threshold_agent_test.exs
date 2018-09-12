defmodule OMG.Burner.ThresholdAgentTest do
  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner.ThresholdAgent, as: Agent

  setup() do
    Agent.start_link()
    :ok
  end

end