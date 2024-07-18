"use client"
import { createPublicClient,parseAbiItem,http } from 'viem';
import React, { useState, useEffect } from 'react';
import { mainnet } from 'viem/chains'

export const publicClient = createPublicClient({
  chain: mainnet,
  transport: http()
})



function BlockInfo() {
  const [block, setBlock] = useState<any>(null);
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    async function getBlockchainLogs() {
      const currentBlock = await publicClient.getBlockNumber();
      const logs = await publicClient.getLogs({
        address: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', // replace with your contract's address
        event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
        fromBlock: currentBlock-2n,
        toBlock: currentBlock
      });
      // console.log(logs);
      setLogs(logs);
      // console.log(parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value, bytes32 indexed transactionId)'));
      return logs;
    }
    async function fetchData() {
      try {
        const unwatch = await publicClient.watchBlocks({
          onBlock: block => {
            // console.log(block);
            setBlock(block); // 假设 setBlock 是一个更新 React 状态的函数
            getBlockchainLogs();

          }
        });

        // 此处可选: 保存 unwatch 函数以便未来停止监听
      } catch (error) {
        console.error('Error fetching block data:', error);
      }
    }
    fetchData();

  }, []); // 空依赖数组表示这个effect只在组件挂载时运行

  if(!block) return <div>Loding</div>
  return (
    <div>
      <h1>Block Information</h1>
      <p>Current Block Number: {Number(block.number)}</p>
      <p>Current Block Hash: {block.hash}</p>
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
    </div>
  );
}
export default BlockInfo;