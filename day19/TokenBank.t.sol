// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract TokenBankTest is Test {
    TokenBank public bank;
    MockERC20 public token;
    address public owner;
    address public recipient;

    function setUp() public {
        owner = address(this);
        recipient = address(0x1);
        token = new MockERC20();
        bank = new TokenBank(address(token), 1000 * 10 ** token.decimals(), recipient);
    }

    function testDeposit() public {
        uint256 depositAmount = 500 * 10 ** token.decimals();

        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        assertEq(bank.getBalance(owner), depositAmount);
        assertEq(token.balanceOf(address(bank)), depositAmount);
    }

    function testWithdraw() public {
        uint256 depositAmount = 500 * 10 ** token.decimals();
        uint256 withdrawAmount = 200 * 10 ** token.decimals();

        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        bank.withdraw(withdrawAmount);

        assertEq(bank.getBalance(owner), depositAmount - withdrawAmount);
        assertEq(token.balanceOf(address(bank)), depositAmount - withdrawAmount);
        assertEq(token.balanceOf(owner), withdrawAmount);
    }

    function testAutomaticTransfer() public {
        uint256 depositAmount = 2000 * 10 ** token.decimals();

        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        uint256 expectedTransfer = depositAmount / 2;
        assertEq(token.balanceOf(recipient), expectedTransfer);
        assertEq(token.balanceOf(address(bank)), depositAmount - expectedTransfer);
    }
}
