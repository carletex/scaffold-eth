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
     * @param account the address of the staker
     * @param tokenId the ID of the Sheep to add to the Barn
    */
    function addSheepToBarn(address account, uint256 tokenId) external {
        // ToDo. Only allow staking owned tokens.
        // ToDo. Only allow to stake sheeps.
        barn[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });

        totalSheepStaked += 1;
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

