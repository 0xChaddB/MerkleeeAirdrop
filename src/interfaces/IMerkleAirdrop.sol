// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMerkleAirdrop
 * @notice Interface for the MerkleAirdrop contract
 * @dev Defines the structure and functionality for a merkle tree-based token airdrop
 */
interface IMerkleAirdrop {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct representing an airdrop claim
     * @param account The address eligible for the airdrop
     * @param amount The amount of tokens claimable
     */
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when tokens are successfully claimed
     * @param account The address that claimed the tokens
     * @param amount The amount of tokens claimed
     */
    event Claimed(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when the provided merkle proof is invalid
     */
    error MerkleAirdrop__InvalidProof();

    /**
     * @notice Thrown when an address attempts to claim tokens more than once
     */
    error MerkleAirdrop__AlreadyClaimed();

    /**
     * @notice Thrown when the signature verification fails
     */
    error MerkleAirdrop__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claims airdrop tokens using a merkle proof and signature
     * @param _account The address claiming the tokens
     * @param _amount The amount of tokens to claim
     * @param _merkleProof The merkle proof for the claim
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function claim(
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Generates the message hash for EIP-712 signature verification
     * @param _account The address of the claimant
     * @param _amount The amount being claimed
     * @return The EIP-712 compliant message hash
     */
    function getMessageHash(address _account, uint256 _amount) external view returns (bytes32);

    /**
     * @notice Returns the merkle root used for verification
     * @return The merkle root
     */
    function getMerkleRoot() external view returns (bytes32);

    /**
     * @notice Returns the airdrop token contract
     * @return The IERC20 token being distributed
     */
    function getAirdropToken() external view returns (IERC20);
}