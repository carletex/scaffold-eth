pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ToDo. Base URI / IPFS
// ToDo. Bg color trait?
contract WolfSheepNFT is ERC721Enumerable, Ownable {
    uint256 public immutable MAX_TOKENS;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // struct to store each token's traits
    struct WolfSheep {
        bool isSheep;
    }

    // number of tokens have been minted so far
    uint16 public totalMinted;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => WolfSheep) public tokenTraits;

    constructor(uint256 _maxTokens) ERC721("WolfSheep game: scaffold-eth", "WSGSE") {
        MAX_TOKENS = _maxTokens;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function mintItem(address to) public returns (uint256) {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();

        require(id <= MAX_TOKENS, "All tokens minted");

        _mint(to, id);

        uint256 seed = random(id);
        // 33% chance of minting a wolf
        tokenTraits[id] = WolfSheep((seed & 0xFFFF) % 2 != 0);
        totalMinted++;

        return id;
    }

    /** READ */
    function getTokenTraits(uint256 tokenId) external view returns (WolfSheep memory) {
        return tokenTraits[tokenId];
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

