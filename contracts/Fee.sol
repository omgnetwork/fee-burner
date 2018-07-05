pragma solidity ^0.4.0;

contract Greeter { 
    string public greeting;

    constructor() public {
        greeting = "Hello";
    }

    function setGreeting(string _greeting) public {
        greeting = _greeting;
    }

    function greet() public view returns (string) {
        return greeting;
    }

    function greet(bytes name) public view returns (bytes) {
        
        bytes memory namedGreeting = new bytes(
            name.length + 1 + bytes(greeting).length
        );

        for(uint i = 0; i < bytes(greeting).length; ++i){
            namedGreeting[i] = bytes(greeting)[i];
        }

        namedGreeting[bytes(greeting).length] = " ";

        for(i = 0; i < name.length; ++i){
            namedGreeting[bytes(greeting).length + i + 1] = name[i];
        }

        return namedGreeting;
    }

}



