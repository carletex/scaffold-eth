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

    // maps tokenId to staked sheeps
    mapping(uint256 => Stake) public barn;
    // Array of staked wolves in pack
    Stake[] public pack;
    // Location index of each Wolf in Pack
    mapping(uint256 => uint256) public packIndices;
    // total of Sheeps staked
    uint256 public totalSheepStaked;
    // total of Wolves staked
    uint256 public totalWolfStaked;

    // Daily token rewards
    uint256 public constant DAILY_TOKEN_RATE = 86400;
    // wolves tax % of claimed tokens
    uint256 public constant TOKEN_CLAIM_TAX_PERCENTAGE = 20;

    /**
     * @param _wsgse reference to the WolfSheep NFT contract
     */
    constructor(address _wsgse) {
        wolfSheepNft = WolfSheepNFT(_wsgse);
        // Empty first element to avoid 0 index.
        pack.push(Stake({
            owner: address(0x0),
            tokenId: uint16(0),
            value: uint80(0)
        }));
    }

    /**
     * Stake a Sheep to the Barn
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function addSheepToBarn(uint256 tokenId) external {
        require(wolfSheepNft.ownerOf(tokenId) == msg.sender, "Not your token");
        require(isSheep(tokenId), "Not a sheep");

        barn[tokenId] = Stake({
            owner: msg.sender,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });

        totalSheepStaked += 1;
    }

    /**
     * Stake a Wolf to the pack
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function addWolfToPack(uint256 tokenId) external {
        require(wolfSheepNft.ownerOf(tokenId) == msg.sender, "Not your token");
        require(!isSheep(tokenId), "Not a wolf");

        packIndices[tokenId] = pack.length;
        pack.push(Stake({
            owner: msg.sender,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        }));

        totalWolfStaked += 1;
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
     * chooses an owner of a random staked Wolf
     * @param seed a pseudo-random value
     * @return the owner of the randomly selected Wolf
     */
    function randomWolfOwner(uint256 seed) external view returns (address) {
        if (totalWolfStaked == 0) return address(0x0);
        return pack[seed % pack.length].owner;
    }

    /**
     * Stake a Wolf to the pack
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function calculateRewards(uint256 tokenId) public view returns (uint256 reward) {
        Stake memory stake = barn[tokenId];
        reward = (block.timestamp - stake.value) * DAILY_TOKEN_RATE / 1 days;
        return reward;
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

