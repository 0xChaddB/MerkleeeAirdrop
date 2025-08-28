// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// External Libraries
import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local Contracts
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

contract DeployMerkleAirdrop is Script {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant _MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant _AMOUNT_TO_TRANSFER = 4 * 25 * 1e18;

    function run() external returns (MerkleAirdrop, SimpleToken) {
        return deployMerkleAirdrop();
    }    

    function deployMerkleAirdrop() public returns (MerkleAirdrop, SimpleToken) {
        vm.startBroadcast();
        SimpleToken _token = new SimpleToken();
        MerkleAirdrop _airdrop = new MerkleAirdrop(_MERKLE_ROOT, IERC20(address(_token)));
        _token.mint(_token.owner(), _AMOUNT_TO_TRANSFER);
        require(_token.transfer(address(_airdrop), _AMOUNT_TO_TRANSFER), "Transfer failed");
        vm.stopBroadcast();
        return (_airdrop, _token);
    }
}