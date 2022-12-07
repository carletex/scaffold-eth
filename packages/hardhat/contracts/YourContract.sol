pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {

    event SetPurpose(address sender, string purpose);

    string public purpose = "Building Unstoppable Apps!!!";
    uint public number = 0;

    constructor() payable {
    // what should we do on deploy?
    }

    function setPurpose(string memory newPurpose) public payable {
      purpose = newPurpose;
      console.log(msg.sender,"set purpose to",purpose);
      emit SetPurpose(msg.sender, purpose);
    }

    function setNumber(uint newNumber) public {
        number = newNumber;
    }

    // to support receiving ETH by default
    receive() external payable {}
    fallback() external payable {}
    }
