defmodule OMG.Burner.StateTest do
  use ExUnitFixtures
  use ExUnit.Case

  alias OMG.Burner.State

  @test_value 10

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
    {:error, _} = State.get_accumulated_fees(token)
  end

  def test_accumulated(token, value) do
    {:ok, ^value} = State.get_accumulated_fees(token)
  end

  def test_pending(token, 0) do
    {:error, _} = State.get_pending_fees(token)
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

#  test "update fee" do
#
#    :ok = State.add_fee(TOKEN0, 69)
#    test_token_values(TOKEN0, @test_value + 69, 0)
#
#  end
#
#  test "preexit fee" do
#
#    {:ok, @test_value} = State.preexit_token(TOKEN0)
#    test_token_values(TOKEN0, 0, @test_value)
#
#  end
#
#
#  test "try to preexit already preexited fee" do
#    # preexit token and add some tokens to accumulator
#    State.preexit_token(TOKEN0)
#    State.add_fee(TOKEN0, @test_value)
#
#
#    # preexitng the same token second time causes an error
#    {:error, :already_preexited} = State.preexit_token(TOKEN0)
#    test_token_values(TOKEN0, @test_value, @test_value)
#
#  end
#
#  test "confirm fee exited" do
#
#    State.preexit_token(TOKEN0)
#    :ok = State.confirm_token_exited(TOKEN0)
#
#    test_token_values(TOKEN0, 0, 0)
#
#  end
#
#
#  test "try preexit fee which accumulated value is 0" do
#
#    State.add_fee(ETH, 0)
#    {:error, :nothing_to_preexit} = State.preexit_token(ETH)
#
#  end
#
#
#  test "preexit and confirm twice" do
#
#    State.preexit_token(TOKEN0)
#    State.add_fee(TOKEN0, @test_value)
#    test_token_values(TOKEN0, @test_value, @test_value)
#
#    :ok = State.confirm_token_exited(TOKEN0)
#    test_token_values(TOKEN0, @test_value, 0)
#
#    State.preexit_token(TOKEN0)
#    :ok = State.confirm_token_exited(TOKEN0)
#    test_token_values(TOKEN0, 0, 0)
#
#  end
#
#  test "cancel token exit" do
#    State.preexit_token(TOKEN0)
#
#    :ok = State.cancel_preexit(TOKEN0)
#    test_token_values(TOKEN0, @test_value, 0)
#
#  end
#
#  test "preexit, add fees and cancel" do
#
#    State.preexit_token(TOKEN0)
#    State.add_fee(TOKEN0, @test_value)
#
#    :ok = State.cancel_preexit(TOKEN0)
#
#    test_token_values(TOKEN0, 2 * @test_value, 0)
#  end
#
#  test "try cancel when nothing to be canceled" do
#
#    {:error, :nothing_to_cancel} = State.cancel_preexit(TOKEN0)
#    test_token_values(TOKEN0, @test_value, 0)
#
#  end
#
#
#  test "adding, pre-exiting, canceling/confirming exitrs does not affect other tokens" do
#
#    State.add_fee(TOKEN1, @test_value)
#    State.add_fee(TOKEN2, @test_value)
#
#    State.preexit_token(TOKEN2)
#    # adding
#    State.add_fee(TOKEN0, 1)
#
#    test_token_values(TOKEN1, @test_value, 0)
#    test_token_values(TOKEN2, 0, @test_value)
#
#    # pre-exiting
#    State.preexit_token(TOKEN0)
#
#    test_token_values(TOKEN1, @test_value, 0)
#    test_token_values(TOKEN2, 0, @test_value)
#
#    # confirmation
#
#    State.confirm_token_exited(TOKEN0)
#
#    test_token_values(TOKEN1, @test_value, 0)
#    test_token_values(TOKEN2, 0, @test_value)
#
#    # canceling
#    State.add_fee(TOKEN0, 1)
#    State.preexit_token(TOKEN0)
#    State.cancel_preexit(TOKEN0)
#
#    test_token_values(TOKEN1, @test_value, 0)
#    test_token_values(TOKEN2, 0, @test_value)
#
#  end

end