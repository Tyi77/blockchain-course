import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("DEXModule", (m) => {
  const aToken = m.contract("AToken");
  const bToken = m.contract("BToken");
  const tyi77DEX = m.contract("Tyi77DEX", [aToken, bToken, 5n]);

  return { aToken, bToken, tyi77DEX };
});
