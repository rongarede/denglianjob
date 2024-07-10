// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NTFMarket.sol";
import "../src/BaseERC20.sol";
import "../src/BaseERC721.sol";

contract ListNFTTest is Test {
    NFTMarketplace ntfMarketplace;
    BaseERC20 baseERC20;
    BaseERC721 baseERC721;

    event NFTListed(uint256 indexed tokenId, address indexed owner, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    function setUp() public {
        // 部署合约并设置初始状态
        baseERC20 = new BaseERC20();
        baseERC721 = new BaseERC721();
        ntfMarketplace  = new NFTMarketplace(address(baseERC721), address(baseERC20));
    }

    // test上架成功
    function testListSuccess() public {
        uint256 tokenId = 1;
        uint256 price = 100 * 10 ** 18;

        baseERC721.mint(address(this), tokenId, "testURI");

        vm.expectEmit(true, true, true, true);
        emit NFTListed(tokenId, address(this), price);

        ntfMarketplace.list(tokenId, price);

        (address owner, uint256 listedPrice, bool isListed) = ntfMarketplace.listings(tokenId);

        assertEq(owner, address(this));
        assertEq(listedPrice, price);
        assertTrue(isListed);
    }

    function testListFailNotOwner() public {
        uint256 tokenId = 2;
        uint256 price = 100 * 10 ** 18;

        baseERC721.mint(address(this), tokenId, "testURI");

        vm.expectRevert("Only NFT owner can list it");
        vm.prank(address(0xdead));
        ntfMarketplace.list(tokenId, price);
    }

    function testListFailAlreadyListed() public {
        uint256 tokenId = 1;
        uint256 price = 100 * 10 ** 18;

        baseERC721.mint(address(this), tokenId, "testURI");
        ntfMarketplace.list(tokenId, price);

        vm.expectRevert("NFT already listed");
        ntfMarketplace.list(tokenId, price);
    }


    function testBuyNFTSuccess() public {
        uint256 tokenId = 1;
        uint256 price = 100 * 10 ** 18;

        // Mint NFT and list it
        baseERC721.mint(address(this), tokenId, "testURI");

        // Approve the marketplace to transfer the NFT on behalf of the owner
        baseERC721.approve(address(ntfMarketplace), tokenId);

        ntfMarketplace.list(tokenId, price);

        // Assign ERC20 tokens to buyer and approve marketplace
        deal(address(baseERC20), address(0xdead), price, true);
        vm.prank(address(0xdead));
        baseERC20.approve(address(ntfMarketplace), price);

        // Buy the NFT
        vm.prank(address(0xdead));
        ntfMarketplace.buyNFT(tokenId);

        // Verify the NFT ownership
        assertEq(baseERC721.ownerOf(tokenId), address(0xdead));

    }



    function testBuyNFTSelfPurchase() public {
        uint256 tokenId = 1;
        uint256 price = 100 * 10 ** 18;

        // Mint NFT and list it
        baseERC721.mint(address(this), tokenId, "testURI");
        ntfMarketplace.list(tokenId, price);

        // Assignment ERC20 tokens to the seller and approve marketplace
        deal(address(baseERC20),address(0xdead),price,true);
        baseERC20.approve(address(ntfMarketplace), price);

        // Approve marketplace to transfer the NFT
        baseERC721.approve(address(ntfMarketplace), tokenId);

        // Attempt to buy the NFT by the seller
        vm.expectRevert("Seller cannot buy their own NFT");
        ntfMarketplace.buyNFT(tokenId);

        // Verify the NFT ownership remains the same
        assertEq(baseERC721.ownerOf(tokenId), address(this));
    }

    //重复购买
    function testBuyNFTAlreadySold() public {
        uint256 tokenId = 1;
        uint256 price = 100 * 10 ** 18;

        // Mint NFT and list it
        baseERC721.mint(address(this), tokenId, "testURI");
        ntfMarketplace.list(tokenId, price);

        // Assignment ERC20 tokens to buyer and approve marketplace
        deal(address(baseERC20),address(0xdead),price,true);
        vm.prank(address(0xdead));
        baseERC20.approve(address(ntfMarketplace), price);

        // Approve marketplace to transfer the NFT
        vm.prank(address(this));
        baseERC721.approve(address(ntfMarketplace), tokenId);

        // Buy the NFT
        vm.prank(address(0xdead));
        ntfMarketplace.buyNFT(tokenId);

        // Attempt to buy the NFT again
        vm.expectRevert("NFT not listed");
        vm.prank(address(0xdead));
        ntfMarketplace.buyNFT(tokenId);
    }

    function testBuyNFTWithInsufficientFunds() public {
        uint256 tokenId = 1;
        uint256 price = 100 * 10 ** 18;

        // Mint NFT and list it
        baseERC721.mint(address(this), tokenId, "testURI");
        ntfMarketplace.list(tokenId, price);

        // Approve marketplace to transfer the NFT
        vm.prank(address(this));
        baseERC721.approve(address(ntfMarketplace), tokenId);

        // Assignment ERC20 tokens to buyer and approve marketplace with insufficient funds
        uint256 insufficientAmount = 50 * 10 ** 18;
        deal(address(baseERC20),address(0xdead),price,true);
        vm.prank(address(0xdead));
        baseERC20.approve(address(ntfMarketplace), insufficientAmount);

        // Attempt to buy the NFT
        vm.expectRevert("Token allowance too low");
        vm.prank(address(0xdead));
        ntfMarketplace.buyNFT(tokenId);
    }


    function testFuzzing(uint256 randomPrice, address randomBuyer) public {
        uint256 tokenId = 1;

        // Constrain randomPrice to be between 0.01 and 10000 tokens
        randomPrice = bound(randomPrice, 0.01 * 10 ** 18, 10000 * 10 ** 18);

        // Mint an NFT to the current contract address
        baseERC721.mint(address(this), tokenId, "testURI");

        // Approve the marketplace to transfer the NFT on behalf of the owner
        baseERC721.approve(address(ntfMarketplace), tokenId);

        // List the NFT
        ntfMarketplace.list(tokenId, randomPrice);

        // Assign ERC20 tokens to the random buyer and approve the marketplace
        deal(address(baseERC20), randomBuyer, randomPrice, true);
        vm.prank(randomBuyer);
        baseERC20.approve(address(ntfMarketplace), randomPrice);

        // Buy the NFT with the random buyer
        vm.prank(randomBuyer);
        ntfMarketplace.buyNFT(tokenId);

        // Verify the NFT ownership
        assertEq(baseERC721.ownerOf(tokenId), randomBuyer);
    }

    function testMarketplaceTokenBalance() public {
        uint256 tokenId = 1;
        uint256 price = 100 * 10 ** 18;

        // Mint NFT and list it
        baseERC721.mint(address(this), tokenId, "testURI");

        // Approve the marketplace to transfer the NFT on behalf of the owner
        baseERC721.approve(address(ntfMarketplace), tokenId);

        ntfMarketplace.list(tokenId, price);
        // Assign ERC20 tokens to buyer and approve marketplace
        deal(address(baseERC20), address(0xdead), price, true);
        vm.prank(address(0xdead));
        baseERC20.approve(address(ntfMarketplace), price);


        // Buy the NFT
        vm.prank(address(0xdead));
        ntfMarketplace.buyNFT(tokenId);

        // Verify the NFT ownership
        assertEq(baseERC721.ownerOf(tokenId), address(0xdead));

        // Ensure the marketplace has zero token balance
        assertEq(baseERC20.balanceOf(address(ntfMarketplace)), 0);

        // Attempt to list and sell again to verify balance
        vm.prank(address(0xdead));
        baseERC721.approve(address(ntfMarketplace), tokenId);
        vm.prank(address(0xdead));
        ntfMarketplace.list(tokenId, price);

        // Assign ERC20 tokens to a new buyer and approve marketplace
        address newBuyer = address(0xbeef);
        deal(address(baseERC20), newBuyer, price, true);
        vm.prank(newBuyer);
        baseERC20.approve(address(ntfMarketplace), price);

        // Buy the NFT with new buyer
        vm.prank(newBuyer);
        ntfMarketplace.buyNFT(tokenId);

        // Verify the NFT ownership
        assertEq(baseERC721.ownerOf(tokenId), newBuyer);

        // Ensure the marketplace has zero token balance
        assertEq(baseERC20.balanceOf(address(ntfMarketplace)), 0);
    }



}
