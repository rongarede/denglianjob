// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NewBank.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployTokenBank is Script {
    function run() external {
        // 开始广播交易
        vm.startBroadcast();

        // 部署 Mock ERC20 代币
        ERC20 token = new ERC20("MockToken", "MTK");

        // 设置初始阈值和接收地址
        uint256 initialThreshold = 1000 * 10 ** token.decimals();
        address recipient = address(0x1);

        // 部署 TokenBank 合约
        TokenBank bank = new TokenBank(address(token), initialThreshold, recipient);

        // 结束广播交易
        vm.stopBroadcast();

        // 输出合约地址
        console.log("TokenBank deployed at:", address(bank));
        console.log("MockToken deployed at:", address(token));
    }
}
