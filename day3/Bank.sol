// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    address public owner;
    mapping(address => uint256) public balances;
    address[] public topDepositors;
    uint256[] public topDeposits;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed from, address indexed to, uint256 amount);

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        balances[msg.sender] += msg.value;
        _updateTopDepositors(msg.sender, balances[msg.sender]);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address user, uint256 amount) public onlyOwner {
        require(balances[user] >= amount, "Insufficient user balance");

        balances[user] -= amount;
        payable(owner).transfer(amount);

        emit Withdrawal(user, owner, amount);
    }

    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    function _updateTopDepositors(address user, uint256 newBalance) internal {
        for (uint i = 0; i < topDepositors.length; i++) {
            if (topDepositors[i] == user) {
                topDeposits[i] = newBalance;
                _sortTopDepositors();
                return;
            }
        }

        if (topDepositors.length < 3) {
            topDepositors.push(user);
            topDeposits.push(newBalance);
        } else {
            if (newBalance > topDeposits[2]) {
                topDepositors[2] = user;
                topDeposits[2] = newBalance;
            }
        }
        _sortTopDepositors();
    }

    function _sortTopDepositors() internal {
        for (uint i = 0; i < topDepositors.length; i++) {
            for (uint j = i + 1; j < topDepositors.length; j++) {
                if (topDeposits[i] < topDeposits[j]) {
                    (topDepositors[i], topDepositors[j]) = (topDepositors[j], topDepositors[i]);
                    (topDeposits[i], topDeposits[j]) = (topDeposits[j], topDeposits[i]);
                }
            }
        }
    }

    function getTopDepositors() public view returns (address[] memory, uint256[] memory) {
        return (topDepositors, topDeposits);
    }
}
