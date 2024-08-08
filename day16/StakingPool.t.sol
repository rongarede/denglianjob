// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/KKToken.sol";
import "../src/StakingPool.sol";

contract StakingPoolTest is Test {
    KKToken public kkToken;
    StakingPool public stakingPool;
    address public user1;

    function setUp() public {
        kkToken = new KKToken();
        stakingPool = new StakingPool(kkToken);
        kkToken.setMinter(address(stakingPool));
        user1 = address(1);
    }

    function testStakeAndClaim() public {
        uint256 initialBalance = user1.balance;

        // User1 stakes 1 ETH
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        stakingPool.stake{value: 1 ether}();

                // Check balance
        uint256 balance1 = stakingPool.balanceOf(user1);
        console.log("balance1 earned:", balance1);

        // Fast forward 10 blocks
        mineBlocks(10);

        // User1 claims rewards
        vm.prank(user1);
        stakingPool.claim();

        // Check balance
        uint256 balance = stakingPool.balanceOf(user1);
        console.log("balance earned:", balance);


    }

    function testGetStake() public {
        uint256 initialBalance = user1.balance;

        // User1 stakes 1 ETH
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        stakingPool.stake{value: 1 ether}();

        // Fast forward 10 blocks
        mineBlocks(10);

        // Get stake info
        vm.prank(user1);
        (uint256 amount, uint256 rewards) = stakingPool.getStake(user1);
        console.log("Staked amount:", amount);
        console.log("Pending rewards:", rewards);

        // Check staked amount and pending rewards
        assertEq(amount, 1 ether, "Incorrect staked amount");
        assertTrue(rewards > 0, "No pending rewards");
    }

    // Helper function to mine blocks
    function mineBlocks(uint256 numBlocks) internal {
        for (uint256 i = 0; i < numBlocks; i++) {
            vm.roll(block.number + 1);
        }
    }
}
