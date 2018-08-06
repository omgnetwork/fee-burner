# User stories

In the following text one can find use cases of fee-burner. 

## Fee exit

#### Preconditions:
- fees available to exit

#### Actors:
- operator

**Note: a microservice works on behalf of the operator**

1. Operator chooses a token of the fees to be claimed.
1. Operator count the sum of the fees available to exit.
1. Operator sends a request to begin fee exit token to the root chain contract. The request consists of the token and the sum.   
1. System starts fees exit.
1. Challenge period is waited.
1. Operator requests to finalise the fees exit.
 
## Exchanging OMG tokens for other token

#### Preconditions: 
- user owns some `OMGs`;
- fee-burner owns some other token;
 
#### Actors:
- user (third person);

1. User chooses token he/she wants to receive for `OMGs`.
1. User checks fee-burner's available funds.
1. User checks exchange rate established by the operator.
1. User sends a transfer approval to the `OmiseGO` contract. 
1. User sends an exchange request to the `fee-burner`.
1. `Fee-burner` checks requested exchange rate with the one currently valid.
1. `Fee-burner` atomically does the following actions:
    1. Sends user's `OMG` tokens to 0xDEAD address.
    1. Sends requested token to the user's address.  


## Changing exchange rate


#### Actors:
- operator

1. Operator chooses token and a new exchange rate.
2. Operator sends a request to change the rate.
3. `Fee-burner` checks whether operation can be completed.
4. `Fee-burner` sets new exchange rate.
5. During a clearance period both rates are valid.
6. After the clearance period only newly created exchange rate is the only valid. 

**Note: the clearance period is hard-coded in the fee burner contract and cannot be changed**