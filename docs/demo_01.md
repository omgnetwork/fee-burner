# Submitting transactions to child chain, exiting fees and doing an exchange

Start geth with the following command
```commandline
user@host:~$ geth --dev --dev.period 1 --rpc --rpcapi personal,web3,eth
```

Then just start an interactive shell
```commandline
user@host:fee-burner$ iex -S mix run --no-start
```

```elixir
# prepare environment
import OMG.Burner.DevHelpers
alias ExW3.Contract
alias OmiseGO.Eth

one_hundred_eth_en = trunc(:math.pow(10, 18) * 100) |> ExW3.encode_option
env = prepare_env!
burner_addr = Contract.address(Burner) |> ExW3.format_address

# prepare config file
env |> create_conf_file |> IO.puts

# add support for Ether in Burner's contract (50 OMGs to 1 Ether)
{:ok, _} = Contract.send(Burner, :addSupportFor, [0, 50, 1], %{gas: 2_000_000, from: env.authority_addr})

# generate parties and send OMGs to Alice
alice = create_unlock_and_fund_entity
bob = create_unlock_and_fund_entity

Contract.send(OMG, :transfer, [alice |> ExW3.format_address, 1_000], %{gas: 2_000_000, from: env.authority_addr})
Contract.call(Burner, :getExchangeRate, [0])

# make deposit
Contract.send(RootChain, :deposit, [], %{gas: 2_000_000, from: alice, value: 1_000_000 |> ExW3.encode_option})
Contract.call(RootChain, :currentDepositBlock)

```

Now assume that some transactions have taken place on the child chain and the operator has some fees to collect

```elixir
# fee exit - note that root chain contract is parametrized and exits has to wait at most 2 seconds
Eth.start_fee_exit(0, 100_000, 20_000_000_000, env.authority_addr, Contract.address(RootChain))
Contract.call(RootChain, :getNextExit, [0])

ExW3.balance(Contract.address(Burner))
Contract.send(RootChain, :finalizeExits, [0], %{gas: 2_000_000, from: env.authority_addr})
ExW3.balance(Contract.address(Burner))

# allow fee-burner to transfer OMGs from alice's account 
Contract.send(OMG, :approve, [burner_addr, 99999999], %{gas: 2_000_000, from: alice})
Contract.call(OMG, :allowance, [alice |> ExW3.format_address, burner_addr])

# check account of DEAD address
Contract.call(OMG, :balanceOf, ["0xdead" |> ExW3.format_address])

# make an exchange
Contract.send(Burner, :exchange, [0, 50, 1, 100, 1], %{from: alice, gas: 2_000_000})

# check balances once again
Contract.call(OMG, :balanceOf, ["0xdead" |> ExW3.format_address])
ExW3.balance(Contract.address(Burner))


# make invalid exchanges
Contract.send(Burner, :exchange, [0, 50, 1, 99, 2], %{from: alice, gas: 2_000_000}) #invalid amounts
Contract.send(Burner, :exchange, [0, 51, 1, 102, 2], %{from: alice, gas: 2_000_000}) # invalid rate

# check balances once again
Contract.call(OMG, :balanceOf, ["0xdead" |> ExW3.format_address])
ExW3.balance(Contract.address(Burner))

# change an exchange rate
Contract.send(Burner, :setExchangeRate, [0, 32, 3], %{gas: 2_000_000, from: env.authority_addr})

# check whether it changed
Contract.call(Burner, :getExchangeRate, [0])
Contract.call(Burner, :getPreviousExchangeRate, [0])

# make an exchange 
Contract.send(Burner, :exchange, [0, 32, 3, 99, 6], %{from: alice, gas: 2_000_000})

# check balances once again
Contract.call(OMG, :balanceOf, ["0xdead" |> ExW3.format_address])
ExW3.balance(Contract.address(Burner))

```

