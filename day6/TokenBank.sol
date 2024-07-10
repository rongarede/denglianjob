// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TokenBank  {
    IERC20 public token;
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 _amount, address /*callbackaddress*/) public {
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        balances[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);

    }

    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        require(token.transfer(msg.sender, _amount), "Transfer failed");

        emit Withdraw(msg.sender, _amount);
    }

    function getBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function onERC20Received(address from, uint256 amount, bytes calldata /*data*/) external returns (bytes4) {
        require(msg.sender == address(token), "Invalid ERC20 token");
        balances[from] += amount;
        emit Deposit(from, amount);
        return this.onERC20Received.selector;
    }

}
