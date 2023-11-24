// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameCharacterNFT is ERC721URIStorage, Ownable {
    
    event CharacterMinted(address owner, uint256 tokenId, string name, uint256 level, uint256 power, string tokenURI);

    uint256 private tokenIdCounter;

    mapping(uint256 => bool) private characterMinted;

    mapping(uint256 => CharacterAttributes) private characterAttributes;

    struct CharacterAttributes {
        string name;
        uint256 level;
        uint256 power;
    }

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        tokenIdCounter = 0; 
    }

    function mintCharacter(string memory name, uint256 level, uint256 power, string memory tokenURI) external onlyOwner {
        uint256 tokenId = tokenIdCounter;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        characterMinted[tokenId] = true;
        characterAttributes[tokenId] = CharacterAttributes(name, level, power);
        tokenIdCounter++;
        emit CharacterMinted(msg.sender, tokenId, name, level, power, tokenURI);
    }

    function isCharacterMinted(uint256 tokenId) external view returns (bool) {
        return characterMinted[tokenId];
    }

    function getCharacterAttributes(uint256 tokenId) external view returns (string memory, uint256, uint256) {
        require(characterMinted[tokenId], "Character not minted");
        CharacterAttributes memory attributes = characterAttributes[tokenId];
        return (attributes.name, attributes.level, attributes.power);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://example.com/metadata/";
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }
}