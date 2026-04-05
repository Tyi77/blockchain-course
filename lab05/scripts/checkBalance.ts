import hre from "hardhat";
import { parseEther } from "viem";
// init viem and networkHelpers
const { viem, networkHelpers } = await hre.network.connect();

const PROXY_ADDRESS = "0xe84eac48ca5b8e9a6a4fee03f6924002a25e8273";
const STAKE_CONTRACT_ADDRESS = "0xa73caE55DF45E8902c5A9df832D1705d6232f61E";
const STUDENT_ID = "313553029";

async function main() {
	const proxyToken = await viem.getContractAt("Lab05TokenV1", PROXY_ADDRESS);
  const stakeForNFT = await viem.getContractAt("StakeForNFT", STAKE_CONTRACT_ADDRESS);

	const addresses = await viem.getWalletClients();
	const myAddress = addresses[0].account.address;

  // Token 的 balance
	const contractBalance = await proxyToken.read.balanceOf([STAKE_CONTRACT_ADDRESS]);
	console.log(`StakeForNFT 的 balance: ${contractBalance}`);

	const myBalance = await proxyToken.read.balanceOf([myAddress]);
	console.log(`我自己的 balance: ${myBalance}`);

	// NFT 的 balance
	const nftBalance = await stakeForNFT.read.balanceOf([myAddress]);
	console.log(`我擁有的 StakeForNFT 數量: ${nftBalance}`);
}

main().catch(console.error);