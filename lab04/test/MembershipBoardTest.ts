import { describe, it } from "node:test";
import assert from "node:assert/strict"
import hre from "hardhat";
import { generateMerkleTree } from "../scripts/generate_merkletree.js";
import membersJson from "../members.json";


// init viem and networkHelpers
const { viem, networkHelpers } = await hre.network.connect();
// get members and generate merkle tree
const members: `0x${string}`[] = membersJson.addresses as `0x${string}`[];
const merkleTree = generateMerkleTree(members);

async function deployFixture() {
  const addresses = await viem.getWalletClients();
  const owner = addresses[0];
  const alice = addresses[1];
  const bob = addresses[2];
  const board = await viem.deployContract("MembershipBoard");
  return { board, owner, alice, bob };
}

describe("Adding Members", function () {
  it("Owner can add a single member via addMember", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    const member = members[0] as `0x${string}`;

    await viem.assertions.emitWithArgs(
      board.write.addMember([member]),
      board,
      "MemberAdded",
      [member],
    );

    const isMember = await board.read.members([member]);
    assert.equal(isMember, true);
  });

  it("Non-owner cannot add a member", async function () {
    const { board, alice } = await networkHelpers.loadFixture(deployFixture);
    const member = members[0];

    await viem.assertions.revertWith(
      board.write.addMember([member], { account: alice.account }),
      "Only the contract owner can execute this TX."
    );
  });

  it("Adding a duplicate member reverts", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    const member = members[0];

    await board.write.addMember([member]); // Added once
    await viem.assertions.revertWith( // Added twice -> revert
      board.write.addMember([member]),
      "Already added this member.",
    );
  });

  it("Owner can batch add members via batchAddMembers", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    const batch = members.slice(0, 500);

    await board.write.batchAddMembers([batch]);

    // Check whether the 0th and 49th member is in the board.
    assert.equal(await board.read.members([batch[0]]), true);
    assert.equal(await board.read.members([batch[49]]), true);
  });

  it("Adding a duplicate in a batch reverts", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);

    const member = members[3];
    await board.write.addMember([member]);

    const batch = members.slice(0, 500);
    await viem.assertions.revertWith(
      board.write.batchAddMembers([batch]),
      "There is at least one address that is already a member.",
    );
  });

  it("All 1,000 members are correctly stored after batch add", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    // Add members for each batch
    const batchSize = 500;
    for (let i = 0; i < members.length; i += batchSize) {
      const batch = members.slice(i, i + batchSize) as `0x${string}`[];
      await board.write.batchAddMembers([batch]);
    }
    // Check the front, middle and last member
    assert.equal(await board.read.members([members[0] as `0x${string}`]), true);
    assert.equal(await board.read.members([members[499] as `0x${string}`]), true);
    assert.equal(await board.read.members([members[999] as `0x${string}`]), true);
  });
});

describe("Setting Merkle Root", function () {
  it("Owner can set the Merkle root", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);

    await viem.assertions.emitWithArgs(
      board.write.setMerkleRoot([merkleTree.root]),
      board,
      "MerkleRootSet",
      [merkleTree.root],
    );
  });

  it("Non-owner cannot set the Merkle root (should revert)", async function () {
    const { board, alice } = await networkHelpers.loadFixture(deployFixture);

    await viem.assertions.revertWith(
      board.write.setMerkleRoot([merkleTree.root], { account: alice.account }),
      "Only the contract owner can execute this TX.",
    );
  });
});

describe("Verification (Mapping)", function () {
  it("Returns true for a registered member", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    const member = members[0];

    await board.write.addMember([member]);
    const result = await board.read.verifyMemberByMapping([member]);
    assert.equal(result, true);
  });

  it("Returns false for a non-member", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    const member = members[0];
    const nonmember = members[1];

    await board.write.addMember([member]);
    const result = await board.read.verifyMemberByMapping([nonmember]);
    assert.equal(result, false);
  });
});

describe("Verification (Merkle Proof)", function () {
  it("Valid proof for a registered member returns true", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    
    await board.write.setMerkleRoot([merkleTree.root]);

    const member = members[0];
    const result = await board.read.verifyMemberByProof([member, merkleTree.getProof(member)]);
    assert.equal(result, true);
  });

  it("Invalid proof returns false", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    
    await board.write.setMerkleRoot([merkleTree.root]);

    const member = members[0];
    const wrongmember = members[1];
    const result = await board.read.verifyMemberByProof([member, merkleTree.getProof(wrongmember)]);
    assert.equal(result, false);
  });

  it("Proof for a non-member returns false", async function () {
    const { board } = await networkHelpers.loadFixture(deployFixture);
    const nonMember = "0x0000000000000000000000000000000000000001" as `0x${string}`;
    const fakeProof: `0x${string}`[] = [];
    
    await board.write.setMerkleRoot([merkleTree.root]);

    const result = await board.read.verifyMemberByProof([nonMember, fakeProof]);
    assert.equal(result, false);
  });
});