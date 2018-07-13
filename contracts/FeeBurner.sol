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
        uint blockNo;
        uint nominator;
        uint denominator;
    }


    address public operator;
    ERC20 public OMGToken;

    mapping (address => ExchangeRate) public exchangeRates; 
    mapping (address => PendingExchangeRate) public pendingExchangeRates;

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
    constructor(address _OMGToken, uint etherNominator, uint etherDenominator)
        public
    {   
        //TODO: should I check this ?
        require(etherNominator > 0);
        require(etherDenominator > 0);
        require(_OMGToken != address(0));

        operator = msg.sender;
        OMGToken = ERC20(_OMGToken);    
        
        exchangeRates[address(0)] = ExchangeRate(etherNominator, etherDenominator);
    }

    /*
     * Public functions
     */
    

    function setExchangeRate(address _token, uint _nominator, uint _denominator)
        public
        onlyOperator
    {
        require(exchangeRates[_token].nominator != 0);
        require(_nominator != 0);
        require(_denominator != 0);
        require(pendingExchangeRates[_token].blockNo == 0);

        pendingExchangeRates[_token] = PendingExchangeRate(block.number, _nominator, _denominator);

    }

    /*
     * Public view functions
     */

     
}




