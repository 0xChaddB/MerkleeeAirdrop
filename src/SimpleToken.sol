// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// External Libraries
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Local Interfaces
import {ISimpleToken} from "./interfaces/ISimpleToken.sol";

/**
 * @title SimpleToken
 * @notice A simple ERC20 token with minting capabilities
 * @dev Extends ERC20 and Ownable for basic token functionality with owner-controlled minting
 */
contract SimpleToken is ISimpleToken, ERC20, Ownable {

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the SimpleToken contract
     * @dev Mints 1,000,000 tokens to the deployer
     */
    constructor() ERC20("Bagel", "BAGEL") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISimpleToken
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}