// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RuggedNFT is ERC721 {
    event Rugged(uint256 indexed tokenId, address indexed loser);
    event Winner(uint256 indexed tokenId, address indexed winner, uint256 value);

    uint256 public mintPrice = 0.05 ether;
    uint256 public nextTokenId = 0;

    uint256 public GAME_START_TIME;
    uint256 public MIN_RUG_INTERVAL_TIME;
    uint256 public LAST_RUG_TIME;

    uint256[] internal tokens;
    mapping(uint256 => bool) public tokensInPlay;
    mapping(uint256 => bool) public tokensRugged;

    // TODO: Fix time conversion
    constructor(uint256 mintPeriodDays, uint256 minRugIntervalMins) ERC721("RuggedNFT", "RUG") {
        GAME_START_TIME = block.timestamp + mintPeriodDays;

        // first rug can occur at start
        LAST_RUG_TIME = GAME_START_TIME - minRugIntervalMins;
        MIN_RUG_INTERVAL_TIME = minRugIntervalMins;
    }

    /**
     * @dev Enter the game by minting into the collection prior to game start.
     */
    function mint() external payable {
        require(msg.value == mintPrice, "RuggedNFT: mint price mismatch");
        require(block.timestamp < GAME_START_TIME, "RuggedNFT: game started!");

        _safeMint(msg.sender, nextTokenId);
        tokensInPlay[nextTokenId] = true;

        unchecked {
            nextTokenId++;
        }
    }

    /**
     * @dev Allow the NFT to be transferrable as long as the token has not been rugged
     */
    function transferFrom(address from, address to, uint256 tokenId) override public {
        require(!tokensRugged[tokenId], "RuggedNFT: token is rugged!");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Dynamic URI depending on the state of the token (Rugged | In Play)
     */
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (tokensRugged[tokenId]) {
            // Rugged
            return "";
        } else {
            // Still In Play
            return "";
        }
    }

    /**
     * @dev Trigger the next token to get RUGGED!
     */
    function rug() external {
        require(ruggable(), "RuggedNFT: not ruggable");

        // since this game is OP-focused and the mempool is private,
        // the block hash is sufficient
        uint256 tokenIndex = uint256(blockhash(block.number)) % tokens.length;
        uint256 rugTokenId = tokens[tokenIndex];

        // remove
        tokens[tokenIndex] = tokens[tokens.length - 1];
        tokens.pop();

        tokensRugged[rugTokenId] = true;
        tokensInPlay[rugTokenId] = false;

        emit Rugged(rugTokenId, super.ownerOf(rugTokenId));
    }

    /**
     * @dev At the end of the game, the winner takes all
     */
    function payout() external {
        require(tokensRemaining() > 0, "RuggedNFT: game is over");
        require(tokensRemaining() == 1, "RuggedNFT: winner has not been determined");

        // remove
        uint256 winnerTokenId = tokens[0];
        tokens.pop();

        uint256 amount = address(this).balance;
        address winner = super.ownerOf(winnerTokenId);

        Address.sendValue(payable(winner), amount);
        emit Winner(winnerTokenId, winner, amount);
    }

    // Getters

    function ruggable() public view returns (bool) {
        if (tokensRemaining() > 1) return false;
        else {
            return LAST_RUG_TIME + MIN_RUG_INTERVAL_TIME <= block.timestamp;
        }
    }

    function tokensRemaining() public view returns (uint256) {
        return tokens.length;
    }
}
