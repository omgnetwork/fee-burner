defmodule OMG.Burner.StateTest do
  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner.State

  @test_value 10

  # TODO: change setup into a fixture
  setup do
    {:ok, pid} = State.start_link()

    State.add_fee(TOKEN0, @test_value)

    {:ok, state: pid}
  end

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

  test "add initial fee" do

    # initially state has accumulated no ETH
    test_token_values(ETH, 0, 0)

    # then add some ETH
    :ok = State.add_fee(ETH, 1)
    test_token_values(ETH, 1, 0)

  end

  test "update fee" do

    :ok = State.add_fee(TOKEN0, 69)
    test_token_values(TOKEN0, @test_value + 69, 0)

  end

  test "move fees of a token to pending" do

    {:ok, @test_value} = State.move_to_pending(TOKEN0)
    test_token_values(TOKEN0, 0, @test_value)

  end


  test "try to preexit already preexited fee" do
    # preexit token and add some tokens to accumulator
    State.move_to_pending(TOKEN0)
    State.add_fee(TOKEN0, @test_value)


    # exiting the same token second time causes an error
    {:error, :exit_already_started} = State.move_to_pending(TOKEN0)
    test_token_values(TOKEN0, @test_value, @test_value)

  end

  test "confirm fee exited" do

    State.move_to_pending(TOKEN0)
    :ok = State.confirm_pending(TOKEN0)

    test_token_values(TOKEN0, 0, 0)

  end


  test "try exit fee which accumulated value is 0" do

    State.add_fee(ETH, 0)
    {:error, :no_such_record} = State.move_to_pending(ETH)

  end


  test "exit and confirm twice" do

    State.move_to_pending(TOKEN0)
    State.add_fee(TOKEN0, @test_value)
    test_token_values(TOKEN0, @test_value, @test_value)

    :ok = State.confirm_pending(TOKEN0)
    test_token_values(TOKEN0, @test_value, 0)

    State.move_to_pending(TOKEN0)
    :ok = State.confirm_pending(TOKEN0)
    test_token_values(TOKEN0, 0, 0)

  end

  test "cancel token exit" do
    State.move_to_pending(TOKEN0)

    :ok = State.cancel_exit(TOKEN0)
    test_token_values(TOKEN0, @test_value, 0)

  end

  test "exit, add fees and cancel" do

    State.move_to_pending(TOKEN0)
    State.add_fee(TOKEN0, @test_value)

    :ok = State.cancel_exit(TOKEN0)

    test_token_values(TOKEN0, 2 * @test_value, 0)
  end

  test "try cancel when nothing to be canceled" do

    {:error, :no_such_record} = State.cancel_exit(TOKEN0)
    test_token_values(TOKEN0, @test_value, 0)

  end

  test "adding, exiting, canceling/confirming exits does not affect other tokens" do

    State.add_fee(TOKEN1, @test_value)
    State.add_fee(TOKEN2, @test_value)

    State.move_to_pending(TOKEN2)
    # adding
    State.add_fee(TOKEN0, 1)

    test_token_values(TOKEN1, @test_value, 0)
    test_token_values(TOKEN2, 0, @test_value)

    # pre-exiting
    State.move_to_pending(TOKEN0)

    test_token_values(TOKEN1, @test_value, 0)
    test_token_values(TOKEN2, 0, @test_value)

    # confirmation

    State.confirm_pending(TOKEN0)

    test_token_values(TOKEN1, @test_value, 0)
    test_token_values(TOKEN2, 0, @test_value)

    # canceling
    State.add_fee(TOKEN0, 1)
    State.move_to_pending(TOKEN0)
    State.cancel_exit(TOKEN0)

    test_token_values(TOKEN1, @test_value, 0)
    test_token_values(TOKEN2, 0, @test_value)

  end

  test "set tx_hash of pending" do

    State.move_to_pending(TOKEN0)

    :ok = State.set_tx_hash_of_pending(TOKEN0, "0x0")

    {:ok, @test_value, "0x0"} = State.get_pending_fees(TOKEN0)

  end

  test "set tx_hash to pending where hash has already been set" do

    State.move_to_pending(TOKEN0)
    :ok = State.set_tx_hash_of_pending(TOKEN0, "0x0")
    {:error, :already_set} = State.set_tx_hash_of_pending(TOKEN0, "0x0")

    {:ok, @test_value, "0x0"} = State.get_pending_fees(TOKEN0)

  end

end