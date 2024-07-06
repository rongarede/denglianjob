// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BigBank.sol";

contract Ownable {
    address private _owner;
    BigBank private _bigBank;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address payable bigBankAddress) {
        _bigBank = BigBank(bigBankAddress);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    // Interface to call withdraw from BigBank
    function withdrawFromBigBank(address user, uint256 amount) public onlyOwner {
        _bigBank.withdraw(user, amount);
    }

    // Set a new admin for BigBank
    function setBigBankAdmin(address newAdmin) public onlyOwner {
        _bigBank.setAdmin(newAdmin);
    }
}
