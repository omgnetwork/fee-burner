pragma solidity ^0.4.0;

import "./ERC20_token/ERC20.sol";

/**
 * @title FeeBurner
 * @author Piotr Zelazko <pitor.zelazko@icloud.com>
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

    /*
     * @notice the exchange rate is a ratio of OMG tokens to otherTokens 
     * @notice ratio = OMGTokens/otherTokens = nominator/denominator
     */
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

    uint constant NEW_RATE_MATURITY_MARGIN = 100;

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
     * @dev Constructor
     * 
     * @param _OMGToken address of OMGToken contract
     * @param _etherNominator nominator of the initial OMG to ETH ratio
     * @param _etherDenominator denominator of the initial OMG to ETH ratio
     */
    constructor(address _OMGToken, uint _etherNominator, uint _etherDenominator)
        public
    {   
        //TODO: should I check this ?
        require(_etherNominator > 0);
        require(_etherDenominator > 0);
        require(_OMGToken != address(0));

        operator = msg.sender;
        OMGToken = ERC20(_OMGToken);    
        
        // At deployment, supports only Ether
        exchangeRates[address(0)] = ExchangeRate(_etherNominator, _etherDenominator);
    }

    /*
     * Public functions
     */
    
    /**
     * @dev Sets new exchange rate for a specified token. 
     * 
     * @notice Note that the new rate will automatically take  
     *         effect after NEW_RATE_MATURITY_MARGIN number of blocks.
     * @notice Once new rate is set it cannot be changed until it has taken effect.
     * 
     * @param _token contract address of the ERC20 token, which rate is changed
     * @param _nominator nominator of the new exchange rate. See ExchangeRate struct.
     * @param _denominator denominator of the new exchange rate. See ExchangeRate struct.  
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




