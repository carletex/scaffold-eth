pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WolfSheepERC20Token is ERC20, Ownable {

    // Mapping with the adddreses that can mint / burn tokens
    mapping(address => bool) allowList;

    constructor() ERC20("WOOL", "WOOL") { }

    /**
     * mints $WOOL
     * @param to the recipient
     * @param amount the amount of $WOOL to mint
     */
    function mint(address to, uint256 amount) external {
        require(allowList[msg.sender], "Not in the allowList");
        _mint(to, amount);
    }

    /**
     * burns $WOOL from a holder
     * @param from the holder of the $WOOL
     * @param amount the amount of $WOOL to burn
    */
    function burn(address from, uint256 amount) external {
        require(allowList[msg.sender], "Not in the allowList");
        _burn(from, amount);
    }

    /**
     * Add an address to the allowList to mint / burn
     * @param controller the address to enable
     */
    function addAddressToAllowList(address controller) external onlyOwner {
        allowList[controller] = true;
    }

    /**
     * Remove an address from the allowList
     * @param controller the address to disbale
     */
    function removeAddressFromAllowList(address controller) external onlyOwner {
        allowList[controller] = false;
    }
}
