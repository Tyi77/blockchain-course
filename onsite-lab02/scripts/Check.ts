import hre from "hardhat";
import { parseAbi, encodeFunctionData } from "viem";

async function main(idx: number) {
  // 1. 初始化網路與 viem
  const { viem } = await hre.network.getOrCreate();

  const studentId = "313553029";
  const factoryAddress = "0x35c73628b4FaD218A2B0B24098D9E0B7CBB45eF7";

  // 2. 定義 Factory 的 ABI (使用樣板字串 Template Literal)
  const abi = parseAbi([
    `function check${idx}(string calldata studentId) external`,
    "function instances(string studentId) external view returns (address, address, address, address, address, address, address, bool, bool, bool, bool)"
  ]);

  // 3. 取得 Client
  const publicClient = await viem.getPublicClient();
  const walletClients = await viem.getWalletClients();
  const walletClient = walletClients[0]; // 使用第一個帳號 (Lab)

  console.log(`🚀 正在為學生 "${studentId}" 驗證 Challenge ${idx}...`);

  try {
    // 4. 準備交易資料並發送
    const data = encodeFunctionData({
      abi,
      functionName: `check${idx}`,
      args: [studentId],
    });

    const hash = await walletClient.sendTransaction({
      to: factoryAddress,
      data,
    });

    console.log("✅ 交易已送出，Hash:", hash);
    console.log("⏳ 等待交易上鏈確認中...");

    // 5. 等待交易確認
    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    if (receipt.status === "success") {
      console.log(`🎉 Challenge ${idx} 驗證成功！你的進度已更新至鏈上。`);
      
      // 6. 讀取並確認狀態
      const instanceData = await publicClient.readContract({
        address: factoryAddress,
        abi,
        functionName: "instances",
        args: [studentId],
      });
      // 陣列中索引 6+idx 的位置即為 challenge 的布林值 (challenge1=7, challenge2=8, challenge3=9)
      console.log(`📌 Challenge ${idx} 完成狀態: ${instanceData[6 + idx] ? "已完成" : "未完成"}`);
    } else {
      console.log(`❌ 驗證交易失敗 (Reverted)，請檢查 Etherscan。`);
    }
  } catch (error: any) {
    console.error("⚠️ 發生錯誤：", error.shortMessage || error.message);
  }
}

// 執行腳本，並帶入你想要的 Challenge 數字
main(1).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
