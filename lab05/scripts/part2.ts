import hre from "hardhat";
import { parseEther } from "viem";
// init viem and networkHelpers
const { viem, networkHelpers } = await hre.network.connect();


const PROXY_ADDRESS = "0xe84eac48ca5b8e9a6a4fee03f6924002a25e8273";
const STAKE_CONTRACT_ADDRESS = "0xa73caE55DF45E8902c5A9df832D1705d6232f61E";
const STUDENT_ID = "313553029";

async function main() {
	const publicClient = await viem.getPublicClient();

  const proxyToken = await viem.getContractAt("Lab05TokenV1", PROXY_ADDRESS);
  const stakeForNFT = await viem.getContractAt("StakeForNFT", STAKE_CONTRACT_ADDRESS);

  // Stake 100 tokens
  const stakeAmount = parseEther("100"); 

  console.log("1. Approving tokens...");
  const tx1 = await proxyToken.write.approve([STAKE_CONTRACT_ADDRESS, stakeAmount]);
  console.log(`Approve TX Hash: ${tx1}`);

	// 等待approve完成
	await publicClient.waitForTransactionReceipt({hash: tx1});
	console.log(`Approve 完成`)

  console.log("2. Staking tokens...");
  const tx2 = await stakeForNFT.write.stake([PROXY_ADDRESS, stakeAmount, STUDENT_ID]);
  console.log(`Stake TX Hash: ${tx2}`);
}

main().catch(console.error);