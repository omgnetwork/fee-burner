pragma solidity ^0.4.0;

import "./ERC20_token/ERC20.sol";

/**
 * @title FeeBurner
 * @dev TODO:
 */
contract FeeBurner { 

    /*
    * Events
    */
    event ExchangeRateChanged(
        address token,
        uint nominator,
        uint denominator
    );

    /*
     * Storage
     */

    // the exchange rate is a ratio of OMG tokens to otherTokens 
    // ratio = OMGTokens/otherTokens = nominator/denominator
    struct ExchangeRate { 
        uint nominator;
        uint denominator;
    } 

    struct PendingExchangeRate {
        uint256 timestamp;
        ExchangeRate newRate;
    }


    address public operator;
    mapping (address => ExchangeRate) public exchangeRates; //TODO: change address to ERC20
    mapping (address => PendingExchangeRate) public pendingExchangeRates; // TODO: change address to ERC20

    /*
     * Modifiers
     */    
    modifier onlyOperator(){
        require(msg.sender == operator);
        _;
    }

    /**
     * Constructor
     */
    constructor()
        public
    {
        operator = msg.sender;
    }

    /*
     * Public functions
     */
    

    function setExchangeRate(address _token, uint _nominator, uint _denominator)
        public
        onlyOperator
    {
        
    }
}



