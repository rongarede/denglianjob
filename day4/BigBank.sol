// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bank.sol";

contract BigBank is Bank {
    address public admin;
    address public ownableContract;
    uint256 public constant MINIMUM_WITHDRAW_AMOUNT = 0.001 ether; //最小提现金额

    modifier onlyAdmin() {
        require(msg.sender == admin, "BigBank: caller is not the admin");
        _;
    }

    modifier onlyOwnable() {
        require(msg.sender == ownableContract, "BigBank: caller is not the Ownable contract");
        _;
    }

    modifier minimumAmount(uint256 amount){
        require(amount >= MINIMUM_WITHDRAW_AMOUNT, "BigBank: Withdrawal amount must be at least 0.001 ether");
        _;
    }

    constructor(address payable _ownableContract) {
        admin = msg.sender;
        ownableContract = _ownableContract;
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    function setOwnableContract(address newOwnableContract) public onlyAdmin {
        ownableContract = newOwnableContract;
    }

    function withdraw(address user, uint256 amount) public override onlyOwnable minimumAmount(amount){
        require(balances[user] >= amount, "Insufficient user balance");

        balances[user] -= amount;
        payable(admin).transfer(amount);

        emit Withdrawal(user, admin, amount);
    }
}
