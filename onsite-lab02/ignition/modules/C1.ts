import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("C1Module", (m) => {
  const tokenA = "0x52fddb524B9975c5CFC53fAd0C43B54807AB5B28";
  const tokenB = "0xe2632E10Da25B80dcE5eE6965eF042FF9Ff29aec";
  const flashLoanPool = "0x534243AAed954e7Cc605F368bcaa391a397F3A7A";
  const dex = "0xF81e0b9Def247690db5D68B57C39c7EE73E53CDb";
  const lender = "0x90b89136303B5eE84a3e872B9aF308DaBCf7eA77";

  const c1 = m.contract("C1", [tokenA, tokenB, flashLoanPool, dex, lender]);

  m.call(c1, "drain");

  return { c1 };
});
