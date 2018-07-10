# Architecture

This is a description of fee-burner's design.

## Modules
Whole system consists of 3 products:
- 2 Ethereum contracts (root chain contract and fee-burner contract), one depends on the other;
- a microservice written in `Elixir`;

### Root chain contract 
This contract is taken from `plasma-contracts` (`root chain contract`), but some modifications will be necessary.
The main modification enables the operator to exit fees, but enforces those exits to be sent to the `fee-burner` contract.

### Fee-burner contract
This is a completely new contract. This contract receives fees and provides an automated marketplace that allows people to send `OMGs` and get the fee-tokens in return. The operator is allowed to set exchange rates at it's sole discretion. `OMGs` sent to this contract get burnt.

### Microservice
The microservice is responsible for periodically starting fees' exits and finalising those that got through the challenge period. 

#### Starting fee exit

From time to time, the microservice should start fees' exit, having previously computed the amount of fees eligible to exit. 
Starting fee exit is calling proper method on root chain contract with specified token and amount as call arguments.

#### Finalising fee exit

After a challenge period, the exit fee should be sent directly to the `fee burner` - the microservice should initialise such a transaction. 

## Interfaces

TODO:

## A picture is worth a thousand words

TODO:

