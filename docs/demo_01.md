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
# perepare environment
import OMG.Burner.DevHelpers
alias ExW3.Contract
alias OmiseGO.Eth

one_hundred_eth_en = trunc(:math.pow(10, 18) * 100) |> ExW3.encode_option
env = prepare_env!
burner_addr = Contract.address(Burner) |> ExW3.format_address

# prepare config file
env |> create_conf_file |> IO.puts

# generate parties and send OMGs to Alice
alice = create_unlock_and_fund_entity
bob = create_unlock_and_fund_entity

Contract.send(OMG, :transfer, [alice |> ExW3.format_address, 1_000], %{gas: 2_000_000, from: env.authority_addr})

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
Contract.send(OMG, :approve, [burner_addr, 100], %{gas: 2_000_000, from: alice})
Contract.call(OMG, :allowance, [alice |> ExW3.format_address, burner_addr])

# check account of DEAD address
Contract.call(OMG, :balanceOf, ["0xdead" |> ExW3.format_address])

# make an exchange
Contract.send(Burner, :exchange, [0, 1, 1, 100, 100], %{from: alice, gas: 2_000_000})

# check balances once again
Contract.call(OMG, :balanceOf, ["0xdead" |> ExW3.format_address])
ExW3.balance(Contract.address(Burner))
```

