# Fee-burner

Fee-burner project is an internship project which should answer the following task.

## Fee handling and automatic fee burner

_Assumes knowledge of Ethereum, Plasma concepts and Tesuji plasma design._

Currently the fees are ignored altogether by everyone.

Very soon (https://www.pivotaltracker.com/story/show/157415836) operator will require fees to be given to him on every transaction, but still the operator won't do anything about the collected funds.

The task is to design and implement the machinery that handles the fees and performs the automatic-OMG-buyback-and-burn-mechanism. The various tokens that get collected by the operator should be made exitable only by a special `FeeBurner` contract. That contract can exit fees, and offers a simple, automated market place that allows people to send in OMGs and get the fee-tokens in return. The operator is allowed to (with some honesty mechanism in place) set the token's prices vs OMG at it's sole discretion. The OMGs validly sent into the `FeeBurner` get burnt.

Task is to provide the `FeeBurner.sol` code (with .py/.js tests, populus-.py prefered) and an Elixir microservice that uses Watcher and Eth to calculate the appropriate amount of fees to exit and starts the fee exits on behalf of `FeeBurner` from time to time.



### Deliverables:
  - plan (end of 2nd week);
  - working solution (1 week before end of internship).
        

### Bonus tasks
* provide a way to use the fees to buy ETH and refund the operator's expenses for `submitBlock` gas, combining it with the trust-less fee burner;
* modify the design so that it isn't operator who set's the buyback price, but the price is market-driven.

