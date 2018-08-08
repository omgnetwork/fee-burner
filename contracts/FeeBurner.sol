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
    struct Rate {
        uint nominator;
        uint denominator;
    } 

    struct ExchangeRate {
        uint blockNo;
        Rate rate;
    }

    address public operator;
    OMG_ERC20 public OMGToken;

    uint constant public NEW_RATE_MATURITY_MARGIN = 5;

    mapping (address => ExchangeRate) public oldExchangeRates;
    mapping (address => ExchangeRate) public exchangeRates;

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
        require(exchangeRates[token].blockNo != 0);
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

    function receive() public payable {}

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

            require(exchangeRates[_token].blockNo == 0);

            ExchangeRate memory exchangeRate = ExchangeRate(block.number, Rate(_nominator, _denominator));

            oldExchangeRates[_token] = exchangeRate;
            exchangeRates[_token] = exchangeRate;

            //TODO: Should I emit an event ?
    }

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

        oldExchangeRates[_token] = exchangeRates[_token];
        exchangeRates[_token] = ExchangeRate(block.number, Rate(_nominator, _denominator));

    }


    /**
     * @dev Exchanges OMGs for the given token and burns received OMGs
     *
     * @param _token contract address of ERC20 token, or 0 for Ether
     * @param _nominator nominator of the rate at which the user wants to make the exchange
     * @param _denominator denominator of the rate at which the user wants to make the exchange
     * @param _omg_amount amount of OMGs to be exchanged and burnt
     * @param _token_amount amount of ERC20 tokens to be exchanged
     *
     * @notice Rate proposed by the user must equal either to newExchangeRate or to oldExchangeRate.
     * @notice Rate cannot equal to the oldExchangeRate when the maturity period of the new rate has passed.  
     */
    function exchange(address _token, uint _nominator, uint _denominator, uint _omg_amount, uint _token_amount)
        public
        supportedToken(_token)
    {

        require(checkRateValidity(_token, _nominator, _denominator));

        //NOTE: Sender may offer more OMGs than demanded by the exchange rate, the exchange is then valid.
        require(_omg_amount.mul(_denominator) >= _token_amount.mul(_nominator));

        OMGToken.transferFrom(msg.sender, address(0xDEAD), _omg_amount);

        if (_token == address(0)){
            msg.sender.transfer(_token_amount);
        }
        else {
            ERC20 token = ERC20(_token);
            token.transfer(msg.sender, _token_amount);
        }

    }

    //TODO: should I leave this convenience method ?
    function exchange(uint _nominator, uint _denominator, uint _omg_amount, uint _ether_amount)
        public
    {
        exchange(address(0), _nominator, _denominator, _omg_amount, _ether_amount);
    }

    /*
     * Public view functions
     */

    /**
     * @dev Returns flat pending exchange rate of the given token. 
     * 
     * @param _token address of an ERC20 token, or 0 in case of Ethereum
     */
    function getExchangeRate(address _token)
        public
        view
        returns (uint, uint, uint)
    {
        ExchangeRate memory exchangeRate = exchangeRates[_token];
        return (exchangeRate.blockNo, exchangeRate.rate.nominator, exchangeRate.rate.denominator);
    }

    /**
     *
     */
    function getOldExchangeRate(address _token)
        public
        view
        returns (uint, uint, uint)
    {
        ExchangeRate memory exchangeRate = oldExchangeRates[_token];
        return (exchangeRate.blockNo, exchangeRate.rate.nominator, exchangeRate.rate.denominator);
    }

    /*
     * Private functions
     */


    /**
     * @notice Should be called having previously checked whether the token is supported
     */
    function checkRateValidity(address _token, uint _nominator, uint _denominator)
        private
        view
        returns (bool)
    {

        Rate memory rate = exchangeRates[_token].rate;

        //NOTE : _nominator and _denominator have once been checked against zero values
        if (rate.nominator == _nominator && rate.denominator == _denominator){
            return true;
        }

        if (!checkMaturityPeriodPassed(_token)){
            rate = oldExchangeRates[_token].rate;
            if (rate.nominator == _nominator && rate.denominator == _denominator){
                return true;
            }
        }

        return false;

    }


    /**
     * @notice Should be called having previously checked whether the token is supported
     */
    function checkMaturityPeriodPassed(address _token)
        private
        view
        returns (bool)
    {

        uint blockNo = exchangeRates[_token].blockNo;

        return blockNo.add(NEW_RATE_MATURITY_MARGIN) <= block.number;

    }

}

