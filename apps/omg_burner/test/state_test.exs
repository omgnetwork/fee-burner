defmodule OMG.Burner.StateTest do
  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner.State

  def test_token_values(token, accumulated, pending) do
    test_accumulated(token, accumulated)
    test_pending(token, pending)
    :ok
  end

  def test_accumulated(token, 0) do
    {:error, :no_such_record} = State.get_accumulated_fees(token)
  end

  def test_accumulated(token, value) do
    {:ok, ^value} = State.get_accumulated_fees(token)
  end

  def test_pending(token, 0) do
    {:error, :no_such_record} = State.get_pending_fees(token)
  end

  def test_pending(token, value) do
    {:ok, ^value, nil} = State.get_pending_fees(token)
  end

  @tag fixtures: [:state]
  test "add initial fee", %{state: :ok} do
    # initially state has accumulated no ETH
    test_token_values(ETH, 0, 0)

    # then add some ETH
    :ok = State.add_fee(ETH, 1)
    test_token_values(ETH, 1, 0)
  end

  @tag fixtures: [:state, :test_value, :initial_token]
  test "update fee", %{state: :ok, test_value: test_value, initial_token: token} do
    :ok = State.add_fee(token, 69)
    test_token_values(token, test_value + 69, 0)
  end

  @tag fixtures: [:state, :test_value, :initial_token]
  test "move fees of a token to pending",
       %{state: :ok, test_value: test_value, initial_token: token} do
    {:ok, ^test_value} = State.move_to_pending(token)
    test_token_values(token, 0, test_value)
  end

  @tag fixtures: [:state, :test_value, :initial_token]
  test "try to start exit of already pending fee",
       %{state: :ok, test_value: test_value, initial_token: token} do
    # pending token and add some tokens to accumulator
    State.move_to_pending(token)
    State.add_fee(token, test_value)

    # exiting the same token second time causes an error
    {:error, :exit_already_started} = State.move_to_pending(token)
    test_token_values(token, test_value, test_value)
  end

  @tag fixtures: [:state, :initial_token]
  test "confirm fee exited", %{state: :ok, initial_token: token} do
    State.move_to_pending(token)
    :ok = State.confirm_pending(token)

    test_token_values(token, 0, 0)
  end

  @tag fixtures: [:state]
  test "try exit fee which accumulated value is 0", %{state: :ok} do
    State.add_fee(ETH, 0)
    {:error, :no_such_record} = State.move_to_pending(ETH)
  end

  @tag fixtures: [:state, :initial_token, :test_value]
  test "exit and confirm twice", %{state: :ok, initial_token: token, test_value: test_value} do
    State.move_to_pending(token)
    State.add_fee(token, test_value)
    test_token_values(token, test_value, test_value)

    :ok = State.confirm_pending(token)
    test_token_values(token, test_value, 0)

    State.move_to_pending(token)
    :ok = State.confirm_pending(token)
    test_token_values(token, 0, 0)
  end

  @tag fixtures: [:state, :initial_token, :test_value]
  test "cancel token exit", %{state: :ok, initial_token: token, test_value: test_value} do
    State.move_to_pending(token)

    :ok = State.cancel_exit(token)
    test_token_values(token, test_value, 0)
  end

  @tag fixtures: [:state, :initial_token, :test_value]
  test "exit, add fees and cancel", %{state: :ok, initial_token: token, test_value: test_value} do
    State.move_to_pending(token)
    State.add_fee(token, test_value)

    :ok = State.cancel_exit(token)

    test_token_values(token, 2 * test_value, 0)
  end

  @tag fixtures: [:state, :initial_token, :test_value]
  test "try cancel when nothing to be canceled", %{state: :ok, initial_token: token, test_value: test_value} do
    {:error, :no_such_record} = State.cancel_exit(token)
    test_token_values(token, test_value, 0)
  end

  @tag fixtures: [:state, :initial_token, :test_value]
  test "adding, exiting, canceling/confirming exits does not affect other tokens",
       %{state: :ok, initial_token: token, test_value: test_value} do
    State.add_fee(TOKEN1, test_value)
    State.add_fee(TOKEN2, test_value)

    State.move_to_pending(TOKEN2)
    # adding
    State.add_fee(token, 1)

    test_token_values(TOKEN1, test_value, 0)
    test_token_values(TOKEN2, 0, test_value)

    # pre-exiting
    State.move_to_pending(token)

    test_token_values(TOKEN1, test_value, 0)
    test_token_values(TOKEN2, 0, test_value)

    # confirmation

    State.confirm_pending(token)

    test_token_values(TOKEN1, test_value, 0)
    test_token_values(TOKEN2, 0, test_value)

    # canceling
    State.add_fee(token, 1)
    State.move_to_pending(token)
    State.cancel_exit(token)

    test_token_values(TOKEN1, test_value, 0)
    test_token_values(TOKEN2, 0, test_value)
  end

  @tag fixtures: [:state, :initial_token, :test_value]
  test "set tx_hash of pending", %{state: :ok, initial_token: token, test_value: test_value} do
    State.move_to_pending(token)

    :ok = State.set_tx_hash_of_pending(token, "0x0")

    {:ok, ^test_value, "0x0"} = State.get_pending_fees(token)
  end

  @tag fixtures: [:state, :initial_token, :test_value]
  test "set tx_hash to pending where hash has already been set", %{
    state: :ok,
    initial_token: token,
    test_value: test_value
  } do
    State.move_to_pending(token)
    :ok = State.set_tx_hash_of_pending(token, "0x0")
    {:error, :already_set} = State.set_tx_hash_of_pending(token, "0x0")

    {:ok, ^test_value, "0x0"} = State.get_pending_fees(token)
  end
end
