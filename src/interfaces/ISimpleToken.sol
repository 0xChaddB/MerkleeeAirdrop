// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISimpleToken
 * @notice Interface for the SimpleToken contract
 * @dev Extends IERC20 with minting functionality
 */
interface ISimpleToken is IERC20 {
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints new tokens to a specified address
     * @param _to The address to receive the minted tokens
     * @param _amount The amount of tokens to mint
     * @dev Only callable by the owner
     */
    function mint(address _to, uint256 _amount) external;
}