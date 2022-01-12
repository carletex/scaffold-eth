pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WolfSheepNFT.sol";
import "./WolfSheepERC20Token.sol";

contract WolfSheepStaking is Ownable {

    // Store a stake's tokenId, earning values and owner.
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    // reference to the WolfSheep NFT contract
    WolfSheepNFT wolfSheepNft;
    // reference to the WolfSheep ERC20 Token contract
    WolfSheepERC20Token wolfSheepERC20Token;

    // maps tokenId to staked sheeps
    mapping(uint256 => Stake) public barn;
    // Array of staked wolves in pack
    Stake[] public pack;
    // Location index of each Wolf in Pack
    mapping(uint256 => uint256) public packIndices;
    // total of Sheeps staked
    uint256 public totalSheepsStaked;
    // total of Wolves staked
    uint256 public totalWolvesStaked;
    // Save rewards when no wolves are staked
    uint256 public unaccountedRewards = 0;

    // Daily token rewards
    uint256 public constant DAILY_WOOL_RATE = 86400;
    // wolves tax % of claimed tokens
    uint256 public constant WOOL_CLAIM_TAX_PERCENTAGE = 20;

    /**
     * @param _wsgse reference to the WolfSheep NFT contract
     */
    constructor(address _wsgse, address _erc20token) {
        wolfSheepNft = WolfSheepNFT(_wsgse);
        wolfSheepERC20Token = WolfSheepERC20Token(_erc20token);
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

        totalSheepsStaked += 1;
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

        totalWolvesStaked += 1;
    }

    /**
     * get $WOOL rewards for a single Sheep and optionally unstake it
     * if not unstaking => 20% tax to the staked Wolves
     * if unstaking => 50% chance all $WOOL is stolen by staked Wolves
     * @param tokenId the ID of the Sheep
     * @param unstake whether or not to unstake the Sheep
     */
    function claimWoolFromSheep(uint256 tokenId, bool unstake) external {
        Stake memory stake = barn[tokenId];
        require(wolfSheepNft.ownerOf(tokenId) == msg.sender, "Not your token");
        require(isSheep(tokenId), "Not a sheep");

        // ToDo. End rewards at some point
        uint256 owed = calculateRewards(tokenId);

        if (unstake) {
            // 50% chance of all $WOOL stolen
            if (random(tokenId) & 1 == 1) {
                _payWolfTax(owed);
                owed = 0;
            }
            wolfSheepNft.safeTransferFrom(address(this), msg.sender, tokenId, "");
            delete barn[tokenId];
            totalSheepsStaked -= 1;
        } else {
            // tax to staked wolves
            _payWolfTax(owed * WOOL_CLAIM_TAX_PERCENTAGE / 100);
            // remainder goes to Sheep owner
            owed = owed * (100 - WOOL_CLAIM_TAX_PERCENTAGE) / 100;

            // reset stake
            barn[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            });
        }

        wolfSheepERC20Token.mint(msg.sender, owed);
    }

    /**
     * add $WOOL to claimable pot for the Pack of Wolves
     * @param amount $WOOL to add to the pot
     */
    function _payWolfTax(uint256 amount) internal {
        // Save the $WOOLF for later if there's no staked wolves
        if (totalWolvesStaked == 0) {
            unaccountedRewards += amount;
            return;
        }

        // Include any unaccounted $WOOL
        // woolPerWolf += (amount + unaccountedRewards) / totalWolvesStaked;
        // unaccountedRewards = 0;
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
        if (totalWolvesStaked == 0) return address(0x0);
        return pack[seed % pack.length].owner;
    }

    /**
     * The rewards gained by sheep staking
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function calculateRewards(uint256 tokenId) public view returns (uint256 reward) {
        Stake memory stake = barn[tokenId];
        reward = (block.timestamp - stake.value) * DAILY_WOOL_RATE / 1 days;
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

