// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NonFungibleToken is ERC721,Ownable {
    
    using Counters for Counters.Counter;
    Counters.Counter public currentTokenId;
    

    //Events
    event NFTMinted (address indexed to, uint256 indexed nftId);
    //totalSupply
    uint8 constant maxSupply = 100;

    //minting Price
    uint8 constant mintingPrice = 100;

    //whitelistDiscount
    uint8 constant discountPrice = 50;

    //mapping address to bool check whitelist addresses
    mapping(address => bool) public isWhiteListed;

    //mapping address to bool , address has availed NFT on discount or Not
    mapping(address =>bool) private hasAvailedNFT;

    constructor() ERC721("Non Fungible Token", "NFT") {}

    string baseUri = "bmd.com/";

     function _baseURI() internal view  override returns (string memory) {
        return baseUri;
    }
    
    //mint NFTs for public
    function publicMint(address to) external payable {
        currentTokenId.increment();
        uint256 tokenId = currentTokenId.current();
        require(tokenId <= maxSupply,"max Supply is 100 Can't mint more");
        require(msg.value == mintingPrice, "Invalid Minting Fee");
        _safeMint(to, tokenId);
        emit NFTMinted(to,tokenId);
       
    }

    //only Owner  address can mint
    function ownerMint() external onlyOwner {
      currentTokenId.increment();
      uint256 tokenId = currentTokenId.current();
      require(tokenId <= maxSupply,"max Supply is 100 Can't mint more");
      _safeMint(msg.sender, tokenId);
      emit NFTMinted(msg.sender,tokenId);
    }
    
    //whitelisted address can mint
    function whiteListedMint() external payable {
       require(isWhiteListed[msg.sender], "Only for whitelisted");
       require(!hasAvailedNFT[msg.sender],"Already Availed on Discount");
       require(msg.value == discountPrice,"Invalid Minting Fee");
       currentTokenId.increment();
       uint256 tokenId = currentTokenId.current();
       require(tokenId <= maxSupply,"max Supply is 100 Can't mint more");
       hasAvailedNFT[msg.sender] = true;
      _safeMint(msg.sender, tokenId);
      emit NFTMinted(msg.sender,tokenId);
    }

    function setWhiteLists(address to, bool status) external onlyOwner {
        isWhiteListed[to] = status;
    }

}