// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// External Libraries
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Local Interfaces
import {IMerkleAirdrop} from "./interfaces/IMerkleAirdrop.sol";

/**
 * @title MerkleAirdrop
 * @notice Contract for distributing tokens via merkle tree-based airdrop with signature verification
 * @dev Implements EIP-712 for secure signature verification and uses merkle proofs for efficient verification
 */
contract MerkleAirdrop is IMerkleAirdrop, EIP712 {

    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The EIP-712 typehash for the AirdropClaim struct
    bytes32 private constant _MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The merkle root for verifying claims
    bytes32 private immutable _MERKLE_ROOT;

    /// @notice The token to be distributed in the airdrop
    IERC20 private immutable _AIRDROP_TOKEN;

    /// @notice Tracks whether an address has already claimed
    mapping(address claimer => bool claimed) private _hasClaimed;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the airdrop contract
     * @param _merkleRoot The merkle root for claim verification
     * @param _airdropToken The token to be distributed
     */
    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("MerkleAirdrop", "1") {
        _MERKLE_ROOT = _merkleRoot;
        _AIRDROP_TOKEN = _airdropToken;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMerkleAirdrop
    function claim(
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (_hasClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (!_isValidSignature(_account, getMessageHash(_account, _amount), _v, _r, _s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));
        if (!MerkleProof.verify(_merkleProof, _MERKLE_ROOT, _leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        _hasClaimed[_account] = true;
        emit Claimed(_account, _amount);
        _AIRDROP_TOKEN.safeTransfer(_account, _amount);
    }
    
    /// @inheritdoc IMerkleAirdrop
    function getMerkleRoot() external view returns (bytes32) {
        return _MERKLE_ROOT;
    }

    /// @inheritdoc IMerkleAirdrop
    function getAirdropToken() external view returns (IERC20) {
        return _AIRDROP_TOKEN;
    }

    /*//////////////////////////////////////////////////////////////
                           PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMerkleAirdrop
    function getMessageHash(address _account, uint256 _amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(_MESSAGE_TYPEHASH, AirdropClaim({account: _account, amount: _amount})))
        );
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that a signature is valid
     * @param _account The expected signer
     * @param _digest The message digest
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     * @return Whether the signature is valid
     */
    function _isValidSignature(
        address _account,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        (address _actualSigner, , ) = ECDSA.tryRecover(_digest, _v, _r, _s);
        return _actualSigner == _account;
    }
}