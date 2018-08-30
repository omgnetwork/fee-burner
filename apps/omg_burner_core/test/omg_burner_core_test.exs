defmodule OMG.BurnerCoreTest do
  use ExUnit.Case
  doctest OMG.BurnerCore

  test "greets the world" do
    assert OMG.BurnerCore.hello() == :world
  end
end
