import hre from "hardhat";
import { parseAbi, encodeFunctionData } from "viem";

async function main() {
  // 1. 初始化
  const { viem } = await hre.network.getOrCreate();
  const liquidator = "0xeA333C83C66D1dbEb5858Ba112dD0D9fC6e901E9";

  const abi = parseAbi([
    "function getPrice() public view returns (uint256)",
    "function isHealthy(address user) public view returns (bool)",
  ]);

  const publicClient = await viem.getPublicClient();
  const walletClient = (await viem.getWalletClients()).at(0);
  
  // getPrice()
  const price = await publicClient.readContract({
    address: liquidator,
    abi,
    functionName: "getPrice",
  });

  console.log("價格為: ", price.toString());

  // isHealthy()
  const isHealthy = await publicClient.readContract({
    address: liquidator,
    abi,
    functionName: "isHealthy",
    args: ["0xDbBfEE4886A043823e50783AAe93eE30b64112e0"],
  });
  console.log("健康嗎: ", isHealthy);
}

main();