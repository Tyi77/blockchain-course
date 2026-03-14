import { network } from "hardhat";

import {
    encodePacked,
    isAddress,
    keccak256,
    parseAbi,
    recoverMessageAddress,
    type Address,
} from "viem";

async function main() {
    // Connect to the specific network.
    const { viem } = await network.connect({
        network: "zircuitTestnet",
    });

    // Inputs
    const tokenAddress = "0x574171cF691B569504978052f8C657F33EA66A35" as Address;
    const spender = "0xFc321D11B44CEb828a09d0e5b9E27C69BaA04e63" as Address; // spender === Bob
    const value = BigInt(100 * 10 ** 18); // 100 Tokens
    const ttlSeconds = 3600n;

    const publicClient = await viem.getPublicClient();
    const walletClients = await viem.getWalletClients();
    const ownerClient = walletClients[1];

    if (!ownerClient) {
        throw new Error("No wallet client found. Check network account config.");
    }

    const owner = ownerClient.account.address;

    const tokenAbi = parseAbi([
        "function nonces(address) view returns (uint256)",
    ]);

    const nonce = await publicClient.readContract({
        address: tokenAddress,
        abi: tokenAbi,
        functionName: "nonces",
        args: [owner],
    });

    const nowSec = BigInt(Math.floor(Date.now() / 1000));
    const deadline = nowSec + ttlSeconds;

    // Keep exact field order and types aligned with MyToken.permit hash.
    const packed = encodePacked(
        ["address", "address", "uint256", "uint256", "uint256", "address"],
        [owner, spender, value, nonce, deadline, tokenAddress],
    );

    const hash = keccak256(packed);

    const signature = await ownerClient.signMessage({
        message: { raw: hash },
    });

    const recovered = await recoverMessageAddress({
        message: { raw: hash },
        signature,
    });

    console.log(
        JSON.stringify(
            {
                network: "zircuitTestnet",
                tokenAddress,
                owner,
                spender,
                value: value.toString(),
                nonce: nonce.toString(),
                deadline: deadline.toString(),
                hash,
                signature,
                recovered,
                recoveredMatchesOwner: recovered.toLowerCase() === owner.toLowerCase(),
                permitArgs: {
                    owner,
                    spender,
                    value: value.toString(),
                    nonce: nonce.toString(),
                    deadline: deadline.toString(),
                    signature,
                },
            },
            null,
            2,
        ),
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});