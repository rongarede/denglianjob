// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multiSigWallet;
    address[] public owners;
    uint256 public numConfirmationsRequired;

    address public owner1 = address(1);
    address public owner2 = address(2);
    address public owner3 = address(3);

    function setUp() public {
        owners = [owner1, owner2, owner3];
        numConfirmationsRequired = 2;
        multiSigWallet = new MultiSigWallet(owners, numConfirmationsRequired);
    }

    function testSubmitTransaction() public {
        vm.startPrank(owner1);
        multiSigWallet.submitTransaction(address(4), 100, "");
        vm.stopPrank();

        (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations) = multiSigWallet.transactions(0);

        assertEq(to, address(4));
        assertEq(value, 100);
        assertEq(data.length, 0);
        assertEq(executed, false);
        assertEq(numConfirmations, 0);
    }

    function testConfirmTransaction() public {
        vm.startPrank(owner1);
        multiSigWallet.submitTransaction(address(4), 100, "");
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();

        (, , , , uint256 numConfirmations) = multiSigWallet.transactions(0);
        assertEq(numConfirmations, 1);

        bool isConfirmed = multiSigWallet.isConfirmed(0, owner1);
        assertEq(isConfirmed, true);
    }

    function testExecuteTransaction() public {
        vm.deal(address(multiSigWallet), 100);

        vm.startPrank(owner1);
        multiSigWallet.submitTransaction(address(4), 100, "");
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(owner2);
        multiSigWallet.confirmTransaction(0);
        multiSigWallet.executeTransaction(0);
        vm.stopPrank();

        (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations) = multiSigWallet.transactions(0);

        assertEq(executed, true);
    }

    function testRevokeConfirmation() public {
        vm.startPrank(owner1);
        multiSigWallet.submitTransaction(address(4), 100, "");
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(owner1);
        multiSigWallet.revokeConfirmation(0);
        vm.stopPrank();

        (, , , , uint256 numConfirmations) = multiSigWallet.transactions(0);
        assertEq(numConfirmations, 0);

        bool isConfirmed = multiSigWallet.isConfirmed(0, owner1);
        assertEq(isConfirmed, false);
    }
}
11122ss