pragma solidity ^0.4.0;

import "./ERC20_token/ERC20.sol";
import "./OMG_ERC20/OMG_ERC20.sol";
import "./math/SafeMath.sol";

/**
 * @title FeeBurner
 * @author Piotr Zelazko <pitor.zelazko@imapp.com>
 * @dev TODO:
 */
contract FeeBurner { 
    
    using SafeMath for uint256;

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

    struct NewExchangeRate {
        uint blockNo;
        ExchangeRate rate;
    }

    address public operator;
    OMG_ERC20 public OMGToken;

    uint constant public NEW_RATE_MATURITY_MARGIN = 100;

    mapping (address => ExchangeRate) public oldExchangeRates;
    mapping (address => NewExchangeRate) public newExchangeRates;

    /*
     * Modifiers
     */    
    modifier onlyOperator(){
        require(msg.sender == operator);
        _;
    }

    modifier checkRate(uint nominator, uint denominator){
        require(nominator > 0);
        require(denominator > 0);
        _;
    }

    modifier supportedToken(address token){
        require(oldExchangeRates[token].nominator != 0);
        _;
    }

    /**
     * @dev Constructor
     * 
     * @param _OMGToken address of OMGToken contract
     */
    constructor(address _OMGToken)
        public
    {   
        //TODO: should I check this ?
        require(_OMGToken != address(0));

        operator = msg.sender;
        OMGToken = OMG_ERC20(_OMGToken);    

    }

    /*
     * Public functions
     */


    /**
     * @dev Receives Eth    
     */

    function () public payable {}
    
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
        supportedToken(_token)
        checkRate(_nominator, _denominator)
    {
        require(checkMaturityPeriodPassed(_token));

        newExchangeRates[_token] = NewExchangeRate(block.number, ExchangeRate(_nominator, _denominator));

    }


    /**
     * @dev Adds support for some token
     * 
     * @notice By setting _token address to 0, support for Ether can be added
     *
     * @param _token contract address of ERC20 token, or 0 for Ether, which support should be added
     * @param _nominator nominator of initial exchange rate. See ExchangeRate struct.
     * @param _denominator denominator of initial exchange rate. See ExchangeRate struct.   
     */
    function addSupportFor(address _token, uint _nominator, uint _denominator)
        public
        onlyOperator
        checkRate(_nominator, _denominator)
    {   

        require(oldExchangeRates[_token].nominator == 0);

        oldExchangeRates[_token] = ExchangeRate(_nominator, _denominator);
        //TODO: Should I emit an event ?
    }

    function exchange(address _token, uint _nominator, uint _denominator, uint _omg_amount, uint _token_amount)
        public
        supportedToken(_token)
    {

        require(checkRateValidity(_token, _nominator, _denominator));

        //NOTE: Sender may offer more OMGs than demanded by the exchange rate, the exchange is then valid.
        require(_omg_amount.mul(_denominator) >= _token_amount.mul(_nominator));

        ERC20 token = ERC20(_token);

        OMGToken.transferFrom(msg.sender, address(0xDEAD), _omg_amount);
        token.transfer(msg.sender, _token_amount);

    }

    /*
     * Public view functions
     */


    function getNewExchangeRate(address _token)
        public
        view
        returns (uint, uint, uint)
    {
        NewExchangeRate memory newRate = newExchangeRates[_token];
        return (newRate.blockNo, newRate.rate.nominator, newRate.rate.denominator);
    }
    /*
     * Private functions
     */

    function checkRateValidity(address _token, uint _nominator, uint _denominator)
        private
        view
        returns (bool)
    {

        NewExchangeRate memory newRate = newExchangeRates[_token];

        //NOTE : _nominator and _denominator have once been checked against zero values
        if (newRate.rate.nominator == _nominator && newRate.rate.denominator == _denominator){
            return true;
        }

        if (!checkMaturityPeriodPassed(_token) || newRate.blockNo == 0){
            ExchangeRate memory oldRate = oldExchangeRates[_token];
            if (oldRate.nominator == _nominator && oldRate.denominator == _denominator){
                return true;
            }
        }

        return false;

    }

    function checkMaturityPeriodPassed(address _token)
        private
        view
        returns (bool)
    {
        NewExchangeRate memory newRate = newExchangeRates[_token];

        return newRate.blockNo.add(NEW_RATE_MATURITY_MARGIN) <= block.number;

    }

}


//TODO: add documentation




