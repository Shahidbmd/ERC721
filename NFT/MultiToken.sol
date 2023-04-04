// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiToken is ERC1155,Ownable {
    IERC20 PayToken;
    constructor(address _payToken) ERC1155("") {
        PayToken = IERC20(_payToken);
    }

    uint256 constant maxSupply = 5;

    //mapping ids to minting Fee
    mapping(uint => uint) private mintingFee;

    //mapping and id to number of NFTs minted
    mapping(uint => uint) private mintedNFTs;

    //mapping ids to nftCopies
    mapping(uint => uint) private nftCopies;

    function mintingFeeIs(uint _id) external view returns(uint) {
        return mintingFee[_id];
    }

    function mintedNftsAre(uint _id) external view returns(uint) {
        return mintedNFTs[_id];
    }
    
    function noOfCopies(uint _id) external view returns(uint) {
        return nftCopies[_id];
    }

    function setMintingFee(uint _id, uint _mintingFee,uint _noOfCopies) external onlyOwner {
        require(_id > 0 && _id <= maxSupply,"Id limit is 5");
        mintingFee[_id] = _mintingFee;
        nftCopies[_id] = _noOfCopies;
    }

    function mint(address account, uint256 id, uint256 amount)
      external
    {
        require(id != 0 && id <= maxSupply,"max limit is 5");
        require((amount + mintedNFTs[id]) <= nftCopies[id], "Crossed Mint Limit");
        uint tokensToPay = (mintingFee[id]) * amount;
        PayToken.transferFrom(msg.sender, address(this),tokensToPay);
        mintedNFTs[id] += amount;
        _mint(account, id, amount,"");  
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        external
    { require(ids.length != 0 && ids.length < maxSupply ,"Max Supply is 5");
      
      uint[] memory Nfts = new uint[](ids.length);
      uint tokensToPay;
      for(uint i=0; i< Nfts.length; i++){
          require(((amounts[i] + mintedNFTs[ids[i]]) <= nftCopies[ids[i]]),"Crossed Mint Limit");
           uint amount = amounts[i] * mintingFee[ids[i]];
           tokensToPay += amount;
           mintedNFTs[ids[i]] += amounts[i];
      }
      
      PayToken.transferFrom(to, address(this),tokensToPay);
      _mintBatch(to, ids, amounts,"");
        
        
    }

}
