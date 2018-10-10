# Summary
The following document has been written in order to summarise the project, describe encountered problems.

## What was implemented and what was not?
The project results in successfully implemented the following parts:
- fee burner contract;
- root chain contract's amends;
- microservice's core.

The project is not finished yet, as the today's implementation of `elixir-omg` does not allow this service to work automatically.
The lacking part of the system is the part that automatically adds fees collected in each transaction being made on child chain.
This is caused by the lack of such information in `elixir-omg` - it has not been decided yet how to implement it. 

## Encountered problems
### elixir-omg as a dependency
When `elixir-omg` project was loaded as a dependency of this project, some problems were met.
The following is the list of the errors and their solutions. 

- `plasma-contracts` dependency must be overridden as the default one does not include contract's amends related to fees' exits.
-  another problem (this time a serious one) is that each dependency by default downloads into `/deps` directory, which results in errors when compiling deps using relative paths.
  For example - in `elixir-omg` we assume that `plasma-contracts` downloads into its `/deps` folder -  let's say `/elixir-omg/deps`, but 
  when it is used as a dependency, `elixir-omg` lands in `/project_root/deps` folder as well as `plasma-contracts`
  ```
  project_root
   +-deps
  | +-elixir-omg
  | +-plasma-contracts
  ```
  but `elixir-omg` expects `plasma-contracts` to be in `/project_root/deps/elixir-omg/deps/plasma-contracts`.
  It is caused by the usage of relative paths and the assumption that `elixir-omg`'s deps will always be stored in its own directory.

   
- there is some problem with config files, in order to make things work, configs from `elixir-omg` had to be copied into this elixir project.
- `libsecp256k1` does not compile out of the box - use the following `{:libsecp256k1, "~> 0.1.9", compile: "make && mix deps.get && mix compile", app: false, override: true}`
- override dependencies where `elixir-omg` uses our own forks.

_NOTE: this list was created in August 2018 - problems may have already been solved or you may encounter some new._   

### elixir-omg limitations 
As of the day this document is created, it is impossible to include this project into `elixir-omg`. 
- Main obstacle is the fact that `elixir-omg` assumes that the authority does not
send any other transactions than deploying root chain contract and committing child chain's state.
This project requires sending `start_fee_exit` transaction by the authority. 
The possible solution would be adding another privileged address or this transaction could be invoked only by 
the fee burner's contract.
- Next limitation is the fact that there is no easily accessible information about the fees collected in 
each transaction. The core of the microservice is written so one can manually add fees to be collected 
and the exit will be automatically started once the threshold is met, but to make it work fully automatically
the microservice must be informed about the collected fees - this part must be implemented in `elixir-omg` itself.
- Next problem is related to the watcher and exit checks. The watcher assumes that an exit is related to an UTXO 
and whenever we start a fee exit the watcher checks through UTXOs to validate the transaction, as fee exit has 
fee exit number instead of UTXO the watcher cannot find related UTXO and informs about an error even though 
it is a correct transaction.  

## Demo
Demo has been written in order to show how does the root chain contract automatically sends tokens to fee burner contract 
and how an exchange is being made. At the time of writing the demo, the microservice was not finished yet, which is why 
it is not included in the demo.    