// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarketplace  {
    struct Listing {
        address owner;
        uint256 price; // 购买该 NFT 需要的 ERC20 Token 数量
        bool isListed; // 是否已上架
    }

    mapping(uint256 => Listing) public listings;
    ERC721 public nftContract;
    IERC20 public erc20Token;

    event NFTListed(uint256 indexed tokenId, address indexed owner, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    constructor(address _nftContract, address _erc20Token) {
        nftContract = ERC721(_nftContract);
        erc20Token = IERC20(_erc20Token);
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nftContract.ownerOf(tokenId) == msg.sender, "Only NFT owner can list it");
        require(!listings[tokenId].isListed, "NFT already listed");

        listings[tokenId] = Listing({
            owner: msg.sender,
            price: price,
            isListed: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }

    function buyNFT(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.isListed, "NFT not listed");
        require(erc20Token.balanceOf(msg.sender) >= listing.price, "Insufficient token balance");
        require(erc20Token.allowance(msg.sender, address(this)) >= listing.price, "Token allowance too low");

        address seller = listing.owner;
        // Transfer ERC20 tokens from buyer to seller
        erc20Token.transferFrom(msg.sender, seller, listing.price);
        // Transfer the NFT from seller to buyer
        nftContract.safeTransferFrom(seller, msg.sender, tokenId);

        // Clean up the listing
        delete listings[tokenId];

        emit NFTSold(tokenId, msg.sender, listing.price);
    }

    // 可选：撤销上架
    function delist(uint256 tokenId) external {
        require(listings[tokenId].isListed, "NFT not listed");
        require(nftContract.ownerOf(tokenId) == msg.sender, "Only NFT owner can delist it");

        delete listings[tokenId];

        emit NFTListed(tokenId, msg.sender, 0); // 0 表示取消上架
    }
}
