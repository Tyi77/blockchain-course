import hre from "hardhat";
import { encodeFunctionData } from "viem";

// init viem and networkHelpers
const { viem, networkHelpers } = await hre.network.connect();

async function main() {
  const addresses = await viem.getWalletClients();
  const deployer = addresses[0];
  console.log("Deploying with account:", deployer.account.address);

  // 1. 部署實作合約 V1
  const impl = await viem.deployContract("Lab05TokenV1", []);
  console.log("Lab05TokenV1 Implementation deployed to:", impl.address);

  // 2. 準備 initialize() 函數的呼叫資料 (ABI encoding)
  // 此步驟將我們在 Lab05TokenV1 中寫的 initialize 封裝成 bytes，以便透過 Proxy 呼叫
  const initData = encodeFunctionData({
    abi: impl.abi,
    functionName: "initialize",
    args: [],
  });

  // 3. 部署 Proxy 合約，並指向 V1 實作，同時執行 initialize
  const proxy = await viem.deployContract("Lab05Proxy", [
    impl.address,
    initData,
  ]);
  console.log("Proxy deployed to:", proxy.address);

  // （選用）透過 Proxy 地址將其視為 Lab05TokenV1 並取得名稱，驗證狀態正確
  const token = await viem.getContractAt("Lab05TokenV1", proxy.address);
  const name = await token.read.name();
  console.log("Token initialized successfully. Name:", name);
}

main().catch(console.error);