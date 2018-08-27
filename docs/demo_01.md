# Submitting transactions to child chain, exiting fees and doing an exchange

## Setting up
### Starting geth and child chain
First of all geth must be started.
and child chain must be started. Assuming that you have followed steps from README file in elixir-omg repository, you just have to start both servers with the following commands:
```commandline
user@host:~$ geth --dev --dev.period 1 --rpc --rpcapi personal,web3,eth
```
In the next step, we will have to configure the app.
Following step will :
- create, fund and unlock authority address;
- deploy 3 contracts: 
    - OMG token contract;
    - fee burner's contract;
    - root chain contract;
- mint OMGs
- create config file.
It can be done with the following command.
```commandline
user@host:fee-burner$ 
```

To start child chain server execute the following command:
```commandline
user@host:omisego-jsonrpc$ iex -S mix run --config ~/config.exs
```

### Deploying contracts
We will have to deploy 3 contracts: 
- OMG token contract
- Fee burner's contract
- Root chain contract

### Configure interactive elixir shell
In order to start interactive shell run the following command
```console
user@host:elixir-omg$  iex -S mix run --config ~/config.exs
```
Next step is to prepare elixir shell:
```elixir
alias OmiseGO.{API, Eth}
alias OmiseGO.API.Crypto
alias OmiseGO.API.State.Transaction
alias OmiseGO.API.TestHelper

# we're going to use the ethereumex's client to geth's JSON RPC
{:ok, _} = Application.ensure_all_started(:ethereumex)

# create parties
alice = TestHelper.generate_entity()
bob = TestHelper.generate_entity()

eth = Crypto.zero_address()

```

## Child chain transactions
### Alice makes a deposit
```elixir
{:ok, deposit_tx_hash} = Eth.DevHelpers.deposit(10, alice_enc)
```
### Alice sends Eth to Bob via child chain

## Exiting fee
### Starting fee exit
### Finalising exit

## Setting exchange rate OMG <-> Eth

## Doing an exchange


## Problems that may happen