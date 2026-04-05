import hardhatViem from "@nomicfoundation/hardhat-viem";
import hardhatViemAssertions from "@nomicfoundation/hardhat-viem-assertions";
import hardhatNodeTestRunner from "@nomicfoundation/hardhat-node-test-runner";
import hardhatNetworkHelpers from "@nomicfoundation/hardhat-network-helpers";
import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [
    hardhatViem,
    hardhatViemAssertions,
    hardhatNodeTestRunner,
    hardhatNetworkHelpers,  
    hardhatToolboxViemPlugin,
  ],
  solidity: {
    profiles: {
      default: {
        version: "0.8.28",
      },
      production: {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("METAMASK_LAB_PRIVATE_KEY"), configVariable("METAMASK_ALICE_PRIVATE_KEY"), configVariable("METAMASK_BOB_PRIVATE_KEY")],
    },
    zircuitTestnet: {
      type: "http",
      url: 'https://garfield-testnet.zircuit.com',
      accounts: [configVariable("METAMASK_LAB_PRIVATE_KEY"), configVariable("METAMASK_ALICE_PRIVATE_KEY"), configVariable("METAMASK_BOB_PRIVATE_KEY")],
    },
  },
  verify: {
    etherscan: {
      enabled: false
    },
    blockscout: {
      enabled: false
    },
    sourcify: {
      enabled: true,
      apiUrl: 'https://sourcify.dev/server',
    }
  },
});
