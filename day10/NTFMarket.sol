// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarketplace {
    using ECDSA for bytes32;

    // Store the order status
    mapping(bytes32 => bool) public orders;

    // Store sell order signatures
    mapping(bytes32 => bytes) public sellOrderSignatures;

    address public owner;
    IERC20 public erc20;
    IERC721 public nft;

    event NFTListed(uint256 indexed tokenId, address indexed owner, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    struct SellOrder {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 price;
    }

    bytes32 private constant SELL_ORDER_TYPEHASH = keccak256(
        "SellOrder(address seller,address nft,uint256 tokenId,uint256 price,uint256 deadline)"
    );

    constructor(address _erc20, address _nft) {
        owner = msg.sender;
        erc20 = IERC20(_erc20);
        nft = IERC721(_nft);
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

    function hashStruct(SellOrder memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            order.seller,
            order.nft,
            order.tokenId,
            order.price,
        ));
    }

    function getSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function buy(
        SellOrder  order,
        bytes  signatureForSellOrder,
        bytes  signatureForApprove,
        bytes  signatureForWL
    ) external {
        // Check whitelist signature
        require(getSigner(hashStruct(Message{msg.sender}), signatureForWL) == owner, "invalid signature");

        // Validate sell order
        bytes32 orderHash = hashStruct(order);
        require(getSigner(orderHash, signatureForSellOrder) == order.seller, "invalid signature");
        require(!orders[orderHash], "order sold");
        orders[orderHash] = true;

        address buyer = msg.sender;

        // Execute ERC20 token transfer
        erc20.permit(buyer, address(this), order.price, signatureForApprove);
        erc20.transferFrom(buyer, order.seller, order.price);

        // Execute NFT transfer
        nft.safeTransferFrom(order.seller, buyer, order.tokenId);
    }
}
