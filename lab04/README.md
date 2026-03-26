# Lab04
## Files
* Membershipboard contract 的檔案在 ./contracts/MembershipBoard.sol
* 鏈外建構 Merkle Tree 的檔案在 ./scripts/generate_merkletree.ts
* Minimum Test 在 ./test/MembershipBoardTest.ts
* Gas-Profiling 我使用 hardhat 3 最新的方法 `$ npx hardhat test --gas-stats` 查看，所以並沒有寫額外的程式碼
## Compile and Run
* `$ npm install`: 安裝所需的 packages
* `$ npx hardhat test --gas-stats`: 跑測試並顯示各個 TX 所需的 Gas
## Gas-Profiling
* 備註
    * batchSize 為 200，因此會執行 `batchAddMembers` 五次
    * setMerkleRoot 和 verifyMemberByProof 的單次 Gas 數值使用 Median 的數值

| Action | Gas Used |
|--------|----------|
| `addMember` (single call) | 47751 |
| `addMember` x1000 (total estimated) | 47751000 |
| `batchAddMembers` (all 1,000) | 5044907 * 5 = 25224535 |
| `setMerkleRoot` | 47447 |
| `verifyMemberByMapping` | 24324 |
| `verifyMemberByProof` | 35520 |
## Questions and Answers
1. **Storage cost comparison:** What is the total gas cost of registering all 1,000 members for each of the three approaches (addMember x1000, batchAddMembers, setMerkleRoot)? Which is cheapest and why?
* A: 分別是 addMember x1000 (47751000), batchAddMembers (25224535), setMerkleRoot (47447)。當然是 setMerkleRoot 所需的 Gas 最便宜，因為他只需要執行一次`SSTORE`儲存一個bytes32就好，其他都要執行整整1000次`SSTORE`以儲存1000個address才行。

2. **Verification cost comparison:** What is the gas cost of verifying a single member using the mapping vs. the Merkle proof? Which is cheaper and why?
* A: 分別是 mapping (24324) 和 Merkle proof (35520)，會是 mapping 用的 Gas 較少。原因是 mapping 只需執行一次`SLOAD`；但 Merkle proof 需要對每個 proof node 做 `keccak256` hash 運算，1,000 個 member 的樹深度約 10 層（log₂1000 ≈ 10），因此需要 10 次 hash，計算量更大。

3. **Trade-off analysis:** The Merkle tree approach is very cheap to store on-chain but requires the verifier to provide a proof. In what scenarios would you prefer the mapping approach over the Merkle tree approach, and vice versa? Consider factors such as:
   - Who pays for the verification gas?
   - How often does the membership list change?
   - Is the full member list public or private?
* A: 列出不同的情景和說明原因
    * 適合 `Mapping`
        * 驗證由合約自己發起（不需 user 提供 proof）
        * 名單頻繁更新（每次加人只需一筆 tx）
        * 名單需要保密（proof 一旦公開就洩漏資訊）
    * 適合 `Merkle Tree`
        * 驗證由 user 自己發起並付 gas（gas 成本轉嫁）
        * 名單超大且不常變動（只需一次 setMerkleRoot）
        * 名單本身是公開的（proof 可鏈外生成）

4. **Batch size experimentation:** Try different batch sizes for `batchAddMembers` (e.g., 50, 100, 250, 500). How does the per-member gas cost change with batch size? Is there a sweet spot?
* A: 先列出不同 batch size 所需的 total Gas

|batchSize|Gas|
|-----|-----|
|50|25586140|
|100|25345090|
|250|25200460|
|500|25152178|
* Gas 下降的幅度隨 batch size 增大而趨緩（效益遞減），且 batch size 越大越接近 block gas limit（30M gas），有 revert 風險。綜合考量，sweet spot 約在 200-250，在顯著的 overhead 攤薄效益和可靠性風險之間取得平衡。