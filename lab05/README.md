# Lab05
## 檔案架構與重點
* Proxy 和兩個版本的 Tokens 在 ./contracts 中
* 部署的程式碼都在 ./scripts 中，根據 Lab05.md 的分段切成 part1 至 part4
* 所有的 addresses 和 transactions 都放在 google form 中
## 問答
* What happened when you called unstake? Did you get your tokens back?
    * 我 call unstake 時沒有被 revert，但我查看 StakeForNFT 的 balance 和自己的 balance 時，發現並沒有真正 unstake 成功。
* How did you retrieve your tokens?
    * 我更新proxy以指向 Lab05TokenV2.sol。裡面強迫指定的 target transfer tokens 至 msg.sender手中，因此我可以強迫 StakeForNFT 把 tokens 傳回給我。
* What does this teach you about interacting with unverified contracts?
    * 只要 contract 沒有被 unverified，裡面的執行邏輯就有可能跟作者自己提供的內容不一樣，這樣很危險，因此未來我不會跟任何沒有被verified的contract交易。