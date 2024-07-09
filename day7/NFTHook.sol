// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface IERC20WithCallback is IERC20 {
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);
}

contract ERC20WithCallback is ERC20, Ownable, IERC20WithCallback {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function transferAndCall(address to, uint256 value, bytes calldata data) external override returns (bool) {
        _transfer(_msgSender(), to, value);
        require(IERC20Receiver(to).onTokenTransfer(_msgSender(), value, data), "ERC20WithCallback: Transfer failed");
        return true;
    }
}

interface IERC20Receiver {
    function onTokenTransfer(address from, uint256 value, bytes calldata data) external returns (bool);
}
