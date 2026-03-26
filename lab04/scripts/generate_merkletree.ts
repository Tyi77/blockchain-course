import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

export interface MerkleTree {
    root: `0x${string}`;
    getProof: (address: `0x${string}`) => `0x${string}`[];
}

export function generateMerkleTree(addresses: `0x${string}`[]): MerkleTree {
    const tree = StandardMerkleTree.of(
        addresses.map((addr) => [addr]),
        ["address"]
    );

    return {
        root: tree.root as `0x${string}`,
        getProof(address: `0x${string}`): `0x${string}`[] {
            return tree.getProof([address]) as `0x${string}`[];
        }
    }
}