// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract NFTMarketplace {
    struct Listing {
        address owner;
        uint256 price; // 购买该 NFT 需要的 ERC20 Token 数量
        bool isListed; // 是否已上架
    }

    struct Stake{
        uint256 amount;
        uint256 rewards;  
        uint256 index;
    }

    mapping(uint256 => Listing) public listings;
    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    uint256 public poolIndex;
    uint256 public constant rewardRate = 30; // 0.3% reward rate (30 basis points)
    IERC721 public nftContract;

    constructor(address _nftContract) {
        nftContract = IERC721(_nftContract);
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nftContract.ownerOf(tokenId) == msg.sender, "Only NFT owner can list it");
        require(!listings[tokenId].isListed, "NFT already listed");

        uint256 fee = price * rewardRate/10000; //小费


        listings[tokenId] = Listing({
            owner: msg.sender,
            price: price+fee,
            isListed: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }
    
    //购买
    function buyNFT(uint256 tokenId) external payable {
        Listing storage listing = listings[tokenId];
        require(listing.isListed, "NFT not listed");
        require(msg.value >= listing.price, "Insufficient ETH");

        address seller = listing.owner;

        (bool ethSuccess, ) = seller.call{value: listing.price}("");
        require(ethSuccess, "eth Transfer failed");
        
        // Transfer the NFT from seller to buyer
        nftContract.safeTransferFrom(seller, msg.sender, tokenId);
        
        uint256 fee = listing.price * rewardRate / 10000 ;
        
        if(totalStaked > 0){
            poolIndex += fee * 1e18 / totalStaked;
        }

        // Clean up the listing
        delete listings[tokenId];
        emit NFTSold(tokenId, msg.sender, listing.price);
    }

        // 质押 ETH
    function stake() external payable {
        require(msg.value > 0, "Must stake more than 0");

        stakes[msg.sender].amount += msg.value;
        totalStaked += msg.value;

        if (stakes[msg.sender].rewards != 0){updaterewards(msg.sender);}

        emit Staked(msg.sender, msg.value);
    }

    // 取消质押
    function unstake(uint256 amount) external  {
        require(updaterewards(msg.sender),"Fail updaterewards");
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");

        userStake.amount -= amount;
        totalStaked -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, amount);
    }

        // 获取用户质押信息
    function getStake(address user) external  returns (uint256 amount, uint256 rewards) {
        require(updaterewards(msg.sender),"Fail updaterewards");
        return (stakes[user].amount, stakes[user].rewards);
    }

    function updaterewards(address account) public returns (bool success){
        Stake storage userStake = stakes[account];

        stakes[account].rewards += userStake.amount * (poolIndex - userStake.index) / 1e18;
        stakes[account].index = poolIndex;
        return true;
    }

        // 提取奖励
    function claim() external {

        require(updaterewards(msg.sender),"Fail updaterewards");
        uint256 reward = stakes[msg.sender].rewards;

        if (reward > 0) {
            stakes[msg.sender].rewards = 0;
            (bool success, ) = msg.sender.call{value: reward}("");
            require(success, "Transfer failed");
            emit claimed(msg.sender, reward);
        }

    }


    event NFTListed(uint256 tokenId,address seller,uint256 price);
    event NFTSold(uint256 tokenId,address buyer, uint256 price);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event claimed(address indexed user, uint256 reward);
}