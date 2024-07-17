"use client"
import { createPublicClient,parseAbiItem,http } from 'viem';
import React, { useState, useEffect } from 'react';
import { mainnet } from 'viem/chains'

export const publicClient = createPublicClient({
  chain: mainnet,
  transport: http()
})

async function getBlockchainLogs() {
  const currentBlock = await publicClient.getBlockNumber();
  const logs = await publicClient.getLogs({
    address: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', // replace with your contract's address
    event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
    fromBlock: currentBlock - 100n,
    toBlock: currentBlock
  });
  console.log(logs);
  // console.log(parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value, bytes32 indexed transactionId)'));
  return logs;
}

const LogsDisplay = () => {
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    getBlockchainLogs().then(setLogs).catch(console.error);
  }, []);

  return (
    <div>
      {logs.length > 0 ? (
        <ul>
          {logs.map((log, index) => (
            <li key={index}>
              From: {log.args.from}, To: {log.args.to}, Value: {log.args.value.toString()}, TxID: {log.transactionHash.toString()}
            </li>
          ))}
        </ul>
      ) : (
        <p>No logs found.</p>
      )}
    </div>
  );
};

export default LogsDisplay;