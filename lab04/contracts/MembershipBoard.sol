// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MembershipBoard {
    address public owner;

    mapping(address => bool) public members;
    event MemberAdded(address indexed member);

    bytes32 public merkleRoot;
    event MerkleRootSet(bytes32 indexed root);

    constructor() {
        owner = msg.sender;
    }

    function addMember(address _member) external onlyOwner {
        require(!members[_member], "Already added this member.");
        members[_member] = true;
        emit MemberAdded(_member);
    }

    function batchAddMembers(address[] calldata _members) external onlyOwner {
        uint256 n = _members.length;
        for (uint256 i = 0; i < n; i++) {
            require(!members[_members[i]], "There is at least one address that is already a member.");
            members[_members[i]] = true;
            emit MemberAdded(_members[i]);
        }
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
        emit MerkleRootSet(_root);
    }

    function verifyMemberByMapping(address _member) external view returns(bool) {
        return members[_member];
    }

    function verifyMemberByProof(address _member, bytes32[] calldata _proof) external view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_member))));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can execute this TX.");
        _;
    }
}
