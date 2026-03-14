// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import {Test} from "forge-std/Test.sol";
import {MyToken} from "../contracts/MyToken.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Sign is Test {
    MyToken myToken;
    uint256 oneToken;

    uint256 alicePK = 0xA11CE;
    uint256 fakeAlicePK = 0xFFA11CE;
    uint256 bobPK = 0xBBB;
    address alice = vm.addr(alicePK);
    address fakeAlice = vm.addr(fakeAlicePK);
    address bob = vm.addr(bobPK);

    function setUp() public {
        myToken = new MyToken();
        oneToken = 10 ** myToken.decimals();

        // Give Alice balance so transferFrom tests are meaningful.
        myToken.transfer(alice, 1_000 * oneToken);
    }

    function _signPermit(uint256 ownerPK, address owner, address spender, uint256 value, uint256 nonce, uint256 deadline) private view returns (bytes memory) {
        // ===Return the signature===
        bytes32 hash = keccak256( // Calculate the hash
            abi.encodePacked(
                owner,
                spender,
                value,
                nonce,
                deadline,
                address(myToken)
            )
        );

        bytes32 message = MessageHashUtils.toEthSignedMessageHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPK, message);
        return abi.encodePacked(r, s, v);
    }

    function test_SignatureVerification() public {
        uint256 value = 100 * oneToken;
        uint256 nonce = myToken.nonces(alice);
        uint256 deadline = block.timestamp + 3 days;

        // alice Signs
        bytes memory aliceSign = _signPermit(alicePK, alice, bob, value, nonce, deadline);

        // permit it
        vm.prank(bob);
        myToken.permit(alice, bob, value, nonce, deadline, aliceSign);

        // bob use fake alice signature and permit it
        bytes memory fakeAliceSign = _signPermit(fakeAlicePK, fakeAlice, bob, value, nonce, deadline);
        vm.prank(bob);
        vm.expectRevert("invalid signature");
        myToken.permit(alice, bob, value, nonce + 1, deadline, fakeAliceSign);
    }

    function test_NonceIncreasesAfterPermit() public {
        uint256 value = 50 * oneToken;
        uint256 nonce = myToken.nonces(alice);
        uint256 deadline = block.timestamp + 1 days;

        bytes memory sig = _signPermit(alicePK, alice, bob, value, nonce, deadline);

        vm.prank(bob);
        myToken.permit(alice, bob, value, nonce, deadline, sig);

        assertEq(myToken.nonces(alice), nonce + 1);
    }

    function test_ReusingSameSignatureFails() public {
        uint256 value = 75 * oneToken;
        uint256 nonce = myToken.nonces(alice);
        uint256 deadline = block.timestamp + 1 days;

        bytes memory sig = _signPermit(alicePK, alice, bob, value, nonce, deadline);

        vm.prank(bob);
        myToken.permit(alice, bob, value, nonce, deadline, sig);

        vm.prank(bob);
        vm.expectRevert("wrong nonce");
        myToken.permit(alice, bob, value, nonce, deadline, sig);
    }

    function test_ExpiredSignatureFails() public {
        uint256 value = 80 * oneToken;
        uint256 nonce = myToken.nonces(alice);
        uint256 deadline = block.timestamp - 1;

        bytes memory sig = _signPermit(alicePK, alice, bob, value, nonce, deadline);

        vm.prank(bob);
        vm.expectRevert("expired");
        myToken.permit(alice, bob, value, nonce, deadline, sig);
    }

    function test_AllowanceUpdatedAfterPermit() public {
        uint256 value = 120 * oneToken;
        uint256 nonce = myToken.nonces(alice);
        uint256 deadline = block.timestamp + 2 days;

        bytes memory sig = _signPermit(alicePK, alice, bob, value, nonce, deadline);

        vm.prank(bob);
        myToken.permit(alice, bob, value, nonce, deadline, sig);

        assertEq(myToken.allowance(alice, bob), value);
    }

    function test_TransferFromWorksAfterPermit() public {
        uint256 permitValue = 200 * oneToken;
        uint256 transferValue = 40 * oneToken;
        uint256 nonce = myToken.nonces(alice);
        uint256 deadline = block.timestamp + 2 days;

        bytes memory sig = _signPermit(alicePK, alice, bob, permitValue, nonce, deadline);

        vm.prank(bob);
        myToken.permit(alice, bob, permitValue, nonce, deadline, sig);

        vm.prank(bob);
        myToken.transferFrom(alice, bob, transferValue);

        assertEq(myToken.balanceOf(bob), transferValue);
        assertEq(myToken.allowance(alice, bob), permitValue - transferValue);
    }

    function test_TransferFromFailsWithoutPermit() public {
        vm.prank(bob);
        vm.expectRevert();
        myToken.transferFrom(alice, bob, 1 * oneToken);
    }

}