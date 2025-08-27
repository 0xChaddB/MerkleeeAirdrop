// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {

    using SafeERC20 for IERC20;
    // some list of addresses
    // allow someone in the list to claim ERC20 tokens

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    event Claim(address account, uint256 amount);

    address[] claimers;
    bytes32 private immutable i_MERKLEROOT;
    IERC20 private immutable i_AIRDROPTOKEN;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    constructor(bytes32 merkleRoot, IERC20 airdropToken){
        i_MERKLEROOT = merkleRoot;
        i_AIRDROPTOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!s_hasClaimed[account], MerkleAirdrop__AlreadyClaimed());
        //calculate using the account and the amiunt, the hash -> leaf node
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_MERKLEROOT, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_AIRDROPTOKEN.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_MERKLEROOT;
    }

        function getAirdropToken() external view returns (IERC20) {
        return i_AIRDROPTOKEN;
    }
}