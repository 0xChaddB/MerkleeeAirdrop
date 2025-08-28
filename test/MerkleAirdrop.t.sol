// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// External Libraries
import {Test} from "forge-std/Test.sol";
import {ZkSyncChainChecker} from "@foundry-devops/src/ZkSyncChainChecker.sol";

// Local Contracts
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {SimpleToken} from "../src/SimpleToken.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import {IMerkleAirdrop} from "../src/interfaces/IMerkleAirdrop.sol";

contract MerkleAidropTest is ZkSyncChainChecker, Test {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    MerkleAirdrop public airdrop;
    SimpleToken public token;

    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT_TO_CLAIM = 25e18;
    uint256 public constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    bytes32 private _proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 private _proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proof = [_proofOne, _proofTwo];
    address public gasPayer;
    address private _user;
    uint256 private _userPrivKey;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Claimed(address indexed account, uint256 amount);

    function setUp() public {
        if (!isZkSyncChain()){
            // deploy with scripts
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new SimpleToken();
            airdrop = new MerkleAirdrop(ROOT, token);
            token.mint(token.owner(), AMOUNT_TO_SEND);
            require(token.transfer(address(airdrop), AMOUNT_TO_SEND), "Transfer failed");
        }
        (_user, _userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    /*//////////////////////////////////////////////////////////////
                              TEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testUsersCanClaim() public {
        uint256 _startingBalance = token.balanceOf(_user);
        bytes32 _digest = airdrop.getMessageHash(_user, AMOUNT_TO_CLAIM);

        // Sign message
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_userPrivKey, _digest);
        
        // Tell Foundry: expect the next call to emit this exact event
        vm.expectEmit(true, false, false, true);
        emit Claimed(_user, AMOUNT_TO_CLAIM); // This is the template/pattern to match
        
        // Gas payer calls claim - this should emit the Claimed event
        vm.prank(gasPayer);
        airdrop.claim(_user, AMOUNT_TO_CLAIM, proof, _v, _r, _s);
        
        // Verify balance changed
        uint256 _endingBalance = token.balanceOf(_user);
        assertEq(_endingBalance - _startingBalance, AMOUNT_TO_CLAIM);
    }
    
    function testCannotClaimTwice() public {
        bytes32 _digest = airdrop.getMessageHash(_user, AMOUNT_TO_CLAIM);
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_userPrivKey, _digest);
        
        // First claim succeeds
        vm.prank(gasPayer);
        airdrop.claim(_user, AMOUNT_TO_CLAIM, proof, _v, _r, _s);
        
        // Second claim fails
        vm.expectRevert(IMerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        vm.prank(gasPayer);
        airdrop.claim(_user, AMOUNT_TO_CLAIM, proof, _v, _r, _s);
    }
    
    function testCannotClaimWithInvalidProof() public {
        bytes32 _digest = airdrop.getMessageHash(_user, AMOUNT_TO_CLAIM);
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_userPrivKey, _digest);
        
        // Create invalid proof
        bytes32[] memory _invalidProof = new bytes32[](2);
        _invalidProof[0] = bytes32(0);
        _invalidProof[1] = bytes32(0);
        
        vm.expectRevert(IMerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        vm.prank(gasPayer);
        airdrop.claim(_user, AMOUNT_TO_CLAIM, _invalidProof, _v, _r, _s);
    }
    
    function testCannotClaimWithInvalidSignature() public {
        bytes32 _digest = airdrop.getMessageHash(_user, AMOUNT_TO_CLAIM);
        
        // Sign with wrong private key
        (, uint256 _wrongKey) = makeAddrAndKey("wrongUser");
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_wrongKey, _digest);
        
        vm.expectRevert(IMerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        vm.prank(gasPayer);
        airdrop.claim(_user, AMOUNT_TO_CLAIM, proof, _v, _r, _s);
    }
    
    function testCannotClaimWrongAmount() public {
        uint256 _wrongAmount = AMOUNT_TO_CLAIM + 1e18;
        bytes32 _digest = airdrop.getMessageHash(_user, _wrongAmount);
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_userPrivKey, _digest);
        
        // Proof is for AMOUNT_TO_CLAIM, not _wrongAmount
        vm.expectRevert(IMerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        vm.prank(gasPayer);
        airdrop.claim(_user, _wrongAmount, proof, _v, _r, _s);
    }
    
    function testAnyoneCanPayGas() public {
        address _randomGasPayer = makeAddr("randomGasPayer");
        bytes32 _digest = airdrop.getMessageHash(_user, AMOUNT_TO_CLAIM);
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_userPrivKey, _digest);
        
        // Anyone can pay gas, tokens go to _user
        vm.prank(_randomGasPayer);
        airdrop.claim(_user, AMOUNT_TO_CLAIM, proof, _v, _r, _s);
        
        assertEq(token.balanceOf(_user), AMOUNT_TO_CLAIM);
        assertEq(token.balanceOf(_randomGasPayer), 0);
    }
}