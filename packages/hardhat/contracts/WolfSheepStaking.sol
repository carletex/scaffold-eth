pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WolfSheepNFT.sol";

contract WolfSheepStaking is Ownable {

    // Store a stake's tokenId, earning values and owner.
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    // reference to the WolfSheep NFT contract
    WolfSheepNFT wolfSheepNft;

    // maps tokenId to staking barn
    mapping(uint256 => Stake) public barn;
    // total of Sheep staked
    uint256 public totalSheepStaked;

    /**
     * @param _wsgse reference to the WolfSheep NFT contract
     */
    constructor(address _wsgse) {
        wolfSheepNft = WolfSheepNFT(_wsgse);
    }

    /**
     * adds a single Sheep to the Barn
     * @param tokenId the ID of the Sheep to add to the Barn
    */
    function addSheepToBarn(uint256 tokenId) external {
        require(wolfSheepNft.ownerOf(tokenId) == msg.sender, "Not your token");
        require(isSheep(tokenId), "You can only stake Sheeps");

        barn[tokenId] = Stake({
            owner: msg.sender,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });

        totalSheepStaked += 1;
    }

    /** READ ONLY */

    /**
     * checks if a token is a Sheep
     * @param tokenId the ID of the token to check
     * @return sheep - whether or not a token is a Sheep
     */
    function isSheep(uint256 tokenId) public view returns (bool sheep) {
        (sheep) = wolfSheepNft.tokenTraits(tokenId);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        )));
    }
}

