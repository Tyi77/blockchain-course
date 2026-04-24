import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("C3Module", (m) => {
  const tokenA = "0x52fddb524B9975c5CFC53fAd0C43B54807AB5B28";
  const tokenB = "0xe2632E10Da25B80dcE5eE6965eF042FF9Ff29aec";
  const flashLoanPool = "0x534243AAed954e7Cc605F368bcaa391a397F3A7A";
  const dex = "0xF81e0b9Def247690db5D68B57C39c7EE73E53CDb";
  const rebalancer = "0x057034a6176Aa116B7fde15035748653fCF5c04f";

  const c3 = m.contract("C3", [tokenA, tokenB, flashLoanPool, dex, rebalancer]);

  m.call(c3, "rebalanceAttack");

  return { c3 };
});
