pragma solidity ^0.4.18;


import "./OMG_ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract OMG_ERC20 is OMG_ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}