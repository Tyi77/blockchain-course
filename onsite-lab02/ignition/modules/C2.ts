import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("C2Module", (m) => {
  const tokenA = "0x52fddb524B9975c5CFC53fAd0C43B54807AB5B28";
  const tokenB = "0xe2632E10Da25B80dcE5eE6965eF042FF9Ff29aec";
  const flashLoanPool = "0x534243AAed954e7Cc605F368bcaa391a397F3A7A";
  const dex = "0xF81e0b9Def247690db5D68B57C39c7EE73E53CDb";
  const liquidator = "0xeA333C83C66D1dbEb5858Ba112dD0D9fC6e901E9";
  const borrower = "0xDbBfEE4886A043823e50783AAe93eE30b64112e0";

  const c2 = m.contract("C2", [tokenA, tokenB, flashLoanPool, dex, liquidator, borrower]);

  m.call(c2, "myLiquidate");

  return { c2 };
});
