// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenBank is KeeperCompatibleInterface, Ownable {
    IERC20 public token;
    mapping(address => uint256) public balances;
    uint256 public transferThreshold;
    address public recipient;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ThresholdExceeded(uint256 totalBalance, uint256 transferAmount);

    constructor(address _tokenAddress, uint256 _initialThreshold, address _initialRecipient) {
        token = IERC20(_tokenAddress);
        transferThreshold = _initialThreshold;
        recipient = _initialRecipient;
    }

    function setTransferThreshold(uint256 _threshold) external onlyOwner {
        transferThreshold = _threshold;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function deposit(uint256 _amount) public {
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        balances[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);

        if (token.balanceOf(address(this)) >= transferThreshold) {
            // Trigger ChainLink Automation to handle the transfer
            performUpkeep("");
        }
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

    // ChainLink Automation functions
    function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = token.balanceOf(address(this)) >= transferThreshold;
    }

    function performUpkeep(bytes calldata /*performData*/) public override {
        uint256 balance = token.balanceOf(address(this));
        if (balance >= transferThreshold) {
            uint256 transferAmount = balance / 2;
            require(token.transfer(recipient, transferAmount), "Transfer failed");
            emit ThresholdExceeded(balance, transferAmount);
        }
    }

    function onERC20Received(address from, uint256 amount, bytes calldata /*data*/) external returns (bytes4) {
        require(msg.sender == address(token), "Invalid ERC20 token");
        balances[from] += amount;
        emit Deposit(from, amount);
        return this.onERC20Received.selector;
    }
}
