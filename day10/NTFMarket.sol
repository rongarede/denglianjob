// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract NFTMarketplace is EIP712{
    using ECDSA for bytes32;

    // Store the order status
    mapping(bytes32 => bool) public orders;

    // Store sell order signatures
    mapping(bytes32 => bytes) public sellOrderSignatures;

    mapping(bytes32 => bool) public filledOrders;

    address public owner;
    IERC20 public erc20;
    IERC721 public nft;

    event NFTListed(uint256 indexed tokenId, address indexed owner, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    struct sellOrderWithSignature {
        address nft;
        uint256 tokenId;
        uint256 price;
        bytes   signature;
    }

    struct ERC20PermitData {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }


    constructor(address _erc20, address _nft) {
        owner = msg.sender;
        erc20 = IERC20(_erc20);
        nft = IERC721(_nft);
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nftContract.ownerOf(tokenId) == msg.sender, "Only NFT owner can list it");
        require(!Listing[tokenId].isListed, "NFT already listed");

        Listing[tokenId] = Listing({
            owner: msg.sender,
            price: price,
            isListed: true

        });



        emit NFTListed(tokenId, msg.sender, price);
    }

    function hashStruct(sellOrderWithSignature memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            order.seller,
            order.nft,
            order.tokenId,
            order.price
        ));
    }

    function getSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(signature);
    }


    bytes32 private constant LISTING_TYPEHASH = keccak256(
        "sellOrderWithSignature(address nft,uint256 tokenId,uint256 price,bytes signature)"
    );

    // ???
    bytes32 private constant WL_SIGNER = keccak256(
        "today is a good day"
    );

    function buyWithWL(
                bytes calldata signatureForWL,
                ERC20PermitData calldata approveData,
                sellOrder calldata sellOrder // sell order
    ) public {

        bytes32 orderHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LISTING_TYPEHASH,
                    sellOrder.nft,
                    sellOrder.tokenId,
                    sellOrder.price,
                    sellOrder.deadline
                )
            )
        );

        // if selled
        require(filledOrders[orderHash]==false,"Order already filled");
        filledOrders[orderHash]=true;


        address nftOwner= IERC721(sellOrder.nft).ownerOf(sellOrder.tokenId);
        require(ECDSA.recover(orderHash, sellOrder.signature)==nftOwner,"Invalid signature");

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WL_TYPEHASH,
                    address(msg.sender)
                )
            )
        );
        address signerForWL = ECDSA.recover(
            digest, signatureForWL
        );
        require(
            signerForWL == WL_SIGNER ,
            "You are not in WL"
        );

        //verify ERC20 permit signature
        IERC20Permit(_erc20).permit(
            msg.sender,
            address(this),
            listing.price,
            approveData.deadline,
            approveData.v,
            approveData.r,
            approveData.s
        );

        bool success = erc20.transferFrom(
                msg.sender,
                listing.seller,
                listing.price
            );
        if (!success) revert PaymentFailed(msg.sender, listing.owner, listing.price);

        // seller must be approve the NFT transfer to this contract
        nft.transferFrom(listing.owner, msg.sender, tokenId);

        emit NFTBought(msg.sender, address(nft), tokenId, listing.price);


    }



}
