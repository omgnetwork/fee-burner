pragma solidity ^0.4.0;

import "./ERC20_token/ERC20.sol";
import "./OMG_ERC20/OMG_ERC20.sol";
import "./math/SafeMath.sol";

/**
 * @title FeeBurner
 * @author Piotr Zelazko <pitor.zelazko@icloud.com>
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

    struct PendingExchangeRate {
        uint blockNo;
        uint nominator;
        uint denominator;
    }

    address public operator;
    OMG_ERC20 public OMGToken;

    uint public balance = 0;

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

    modifier checkRate(uint nominator, uint denominator){
        require(nominator > 0);
        require(denominator > 0);
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

    function () public payable {
        balance = balance.add(msg.value);
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
        checkRate(_nominator, _denominator)
    {
        require(exchangeRates[_token].nominator != 0);
        require(pendingExchangeRates[_token].blockNo == 0);

        pendingExchangeRates[_token] = PendingExchangeRate(block.number, _nominator, _denominator);

    }


    /**
     * @dev Adds support for some token
     * 
     * @notice By setting _token address to 0, support for Ehter can be added
     *
     * @param _token contract address of ERC20 token, or 0 for Ether, which support should be added
     * @param _nominator nominator of intial exchange rate. See ExchangeRate struct.
     * @param _denominator denominator of initial exchange rate. See ExchangeRate struct.   
     */
    function addSupportFor(address _token, uint _nominator, uint _denominator)
        public
        onlyOperator
        checkRate(_nominator, _denominator)
    {   
        
        require(exchangeRates[_token].nominator == 0);

        exchangeRates[_token] = ExchangeRate(_nominator, _denominator);
        //TODO: Should I emit an event ?
    }

    // TODO
    function exchange(address _token, uint _nominator, uint _denominator, uint _omg_amount, uint _token_amount)
        public
    {

        // 1 ->
        
        OMGToken.transferFrom(msg.sender, address(0xDEAD), _omg_amount);
        
        // <- 1

    }

    function foo(address token)
        public
    {
        
        // 1
        // OMGToken.transferFrom(msg.sender, address(0xDEAD), 10);

        // 2
        // OMG_ERC20 omg = OMG_ERC20(token);
        // omg.transferFrom(msg.sender, address(0xDEAD), 10);

        // 3 : does not work !
        // ERC20 otherToken = ERC20(token);
        // otherToken.transferFrom(msg.sender, address(0xDEAD), 10);

        // 4
        // OMGToken.approve(0xDEAD, 1000);

        // 5
        ERC20 otherToken = ERC20(token);
        otherToken.approve(0xDEAD, 1000);

        // 6 
        // OMG_ERC20 omg = OMG_ERC20(token);
        // omg.approve(0xDEAD, 1000);

        // omg.transfer(0xDEAD, 11);
        
        // uint x = omg.balanceOf(0xDEAD);

    }

    /*
     * Public view functions
     */

     
}




