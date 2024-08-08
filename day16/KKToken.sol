// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/NFT.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace public marketplace;
    BaseERC721 public nft;

    address public owner;
    address public staker;
    address public buyer;
    address public seller;
    uint256 public initialBalance = 1 ether;

    function setUp() public {
        owner = address(this);
        staker = vm.addr(1);
        buyer = vm.addr(2);
        seller = vm.addr(3);

        // 部署 Mock NFT 合约
        nft = new BaseERC721("haha","HA","ipfs://");

        // 部署 NFTMarketplace 合约
        marketplace = new NFTMarketplace(address(nft));

        // 给 staker 账户初始余额
        vm.deal(staker, initialBalance);
        vm.deal(buyer, 5 ether);

        vm.prank(seller);
        nft.mint(seller,1,"ipfs://");
    }

    function testStakeAndClaimRewards() public {
        // 质押 ETH
        uint256 stakeAmount = 1 ether;
        vm.prank(staker);
        marketplace.stake{value: stakeAmount}();

        // 检查质押金额
        (uint256 amount, uint256 rewards) = marketplace.getStake(staker);
        assertEq(amount, stakeAmount);
        assertEq(rewards, 0);

        // staker 上架 NFT
        uint256 tokenId = 1;
        uint256 nftPrice = 2 ether;
        vm.prank(seller);
        nft.approve(address(marketplace), tokenId);
        vm.prank(seller);
        marketplace.list(tokenId, nftPrice);

        // buyer 购买 NFT
        uint256 fee = (nftPrice * marketplace.rewardRate()) / 10000;
        uint256 totalPrice = nftPrice + fee;
        vm.prank(buyer);
        marketplace.buyNFT{value: totalPrice}(tokenId);

        // 模拟时间流逝
        vm.warp(block.timestamp + 1 days);

        // 获取质押信息，更新奖励
        vm.prank(staker);
        marketplace.getStake(staker);

        // 检查奖励是否提取成功
        (, rewards) = marketplace.getStake(staker);
        emit log_named_uint("Staker rewards before claim: ", rewards);

        // 提取奖励
        uint256 initialStakerBalance = staker.balance;
        vm.prank(staker);
        marketplace.claim();

        // 检查奖励是否提取成功
        (, rewards) = marketplace.getStake(staker);
        assertEq(rewards, 0);
    }

}

