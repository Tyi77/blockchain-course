import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("TokenTradeModule", (m) => {
  const catToken = m.contract("CatToken");
  const dogToken = m.contract("DogToken");
  const tokenTrade = m.contract("TokenTrade", [catToken, dogToken]);



  return { catToken, dogToken, tokenTrade };
});
