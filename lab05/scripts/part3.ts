import hre from "hardhat";
import { parseEther } from "viem";
// init viem and networkHelpers
const { viem, networkHelpers } = await hre.network.connect();

const PROXY_ADDRESS = "0xe84eac48ca5b8e9a6a4fee03f6924002a25e8273";
const STAKE_CONTRACT_ADDRESS = "0xa73caE55DF45E8902c5A9df832D1705d6232f61E";

async function main() {
	const proxyToken = await viem.getContractAt("Lab05TokenV1", PROXY_ADDRESS);
  const stakeForNFT = await viem.getContractAt("StakeForNFT", STAKE_CONTRACT_ADDRESS);

  // 嘗試 Unstake
  console.log("3. Trying to Unstake");
  try {
    const tx3 = await stakeForNFT.write.unstake();
    console.log(`Unstake TX Hash: ${tx3}`);

		const contractBalance = await proxyToken.read.balanceOf([STAKE_CONTRACT_ADDRESS]);
		console.log(`StakeForNFT 的 balance: ${contractBalance}`);

		const addresses = await viem.getWalletClients();
		const myAddress = addresses[0].account.address;
		const myBalance = await proxyToken.read.balanceOf([myAddress]);
		console.log(`我自己的 balance: ${myBalance}`);
  } catch (error) {
    console.error("Unstake Failed!");
  }
}

main().catch(console.error);