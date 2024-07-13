import { createPublicClient, http, parseAbiItem } from 'viem';
import { mainnet } from 'viem/chains';

// Replace these values with your own
const providerUrl = 'https://mainnet.infura.io/v3/5c212d771f7645abae7390ddaf889fbe';
const nftContractAddress = '0x0483b0dfc6c78062b9e999a82ffb795925381415';
const tokenId = BigInt(1);  // Replace with the tokenId you want to check, converted to bigint

// ERC721 ABI
const abi = [
  parseAbiItem('function ownerOf(uint256 tokenId) view returns (address)'),
  parseAbiItem('function tokenURI(uint256 tokenId) view returns (string)')
];

// Create a public client
const client = createPublicClient({
  chain: mainnet,
  transport: http(providerUrl),
});

async function main() {
  try {
    // Get the owner of the token
    const owner = await client.readContract({
      address: nftContractAddress,
      abi: abi,
      functionName: 'ownerOf',
      args: [tokenId],
    });

    console.log(`Owner of token ${tokenId}: ${owner}`);

    // Get the token URI
    const tokenURI = await client.readContract({
      address: nftContractAddress,
      abi: abi,
      functionName: 'tokenURI',
      args: [tokenId],
    });

    console.log(`Token URI of token ${tokenId}: ${tokenURI}`);
  } catch (error) {
    console.error(error);
  }
}

main();
