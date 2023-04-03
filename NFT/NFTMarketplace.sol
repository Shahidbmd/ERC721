// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarketplace is ERC721Holder {
    uint256 orderId = 1;
    uint public constant platformFee = 10;
    address immutable owner;
    constructor(){
        owner = msg.sender;
    }

    //Events
    event NFTsStatus (uint indexed _orderId, uint indexed _NFTId, IERC721 indexed _nftAddress, uint _paymentId, address _owner);
    event pamentMethods (uint indexed _paymentId, IERC20 indexed _paymentTokens);  

    //Order Enum
    enum OrderStatus {
     Open,
     Filled,
     Cancelled
    }
    
    //Listing Nfts data struct 
    struct nftsData {
        uint NFTId;
        uint NFTprice;
        uint paymentId;
        IERC721 nftAddress;
        address owner;
    }
    
    //mapping orderId to nftsData
    mapping(uint => nftsData) private setNFTsData;

    //mapping id to token Addresses
    mapping(uint => IERC20) public paymentTokens;

    //mapping orderId to OrderStaus
    mapping(uint => OrderStatus) private NFT_Status;
     
    //set Payment methods
    function setPaymentTokens(uint _paymentId,IERC20 _paymentToken) external{
        require(msg.sender == owner,"only Owner allowed");
        require(address(_paymentToken) != address(0),"invalid TokenAddress");
        isValidPaymentId(_paymentId);
        paymentTokens[_paymentId] = _paymentToken;
        emit pamentMethods(_paymentId, _paymentToken);
    }

    //list ERC721 NFTs
    function listForSale(uint _NFTId, uint _nftPrice , uint _paymentId, IERC721 _nftAddress) external {
        isValidValue(_NFTId);
        isValidPrice(_nftPrice);
        isValidPaymentId(_paymentId);
        require(address(_nftAddress) != address(0),"invalid NFT address");
        transferNFT(_nftAddress,msg.sender,address(this),_NFTId);
        NFT_Status[orderId] = OrderStatus.Open;
        setNFTsData[orderId] = nftsData(_NFTId,_nftPrice,_paymentId,_nftAddress,msg.sender);
        emit NFTsStatus(orderId, _NFTId, _nftAddress, _paymentId, msg.sender);
        orderId++;
    }
     
    //cancel listed NFTs
    function cancelListing(uint _orderId) external {
        nftsData memory NFTData = setNFTsData[_orderId];
        require(msg.sender == setNFTsData[_orderId].owner, "only Owner can cancel Listing");
        require(NFT_Status[orderId] == OrderStatus.Open,"NFT Not For Sale");
        NFT_Status[_orderId] = OrderStatus.Cancelled;
        transferNFT(NFTData.nftAddress,address(this),msg.sender,NFTData.NFTId);
        delete setNFTsData[_orderId];
        emit NFTsStatus(_orderId, NFTData.NFTId, NFTData.nftAddress, NFTData.paymentId,NFTData.owner);
    }
    
    //Buy Listed Nfts
    function buyNFts(uint _orderId) external {
        nftsData memory NFTData = setNFTsData[_orderId];
        require(NFT_Status[orderId] == OrderStatus.Open,"NFT Not For Sale");
        require(msg.sender != NFTData.owner, "owner can't buy");
        uint256 marketplaceFee = NFTData.NFTprice /platformFee; 
        uint256 payToOwner = NFTData.NFTprice - marketplaceFee;
        paymentGateway(paymentTokens[NFTData.paymentId], msg.sender, address(this),marketplaceFee);
        paymentGateway(paymentTokens[NFTData.paymentId], msg.sender, NFTData.owner,payToOwner);
        transferNFT(NFTData.nftAddress,address(this), msg.sender,NFTData.NFTId);
        NFT_Status[_orderId] = OrderStatus.Filled;
        delete setNFTsData[_orderId];
        emit NFTsStatus(_orderId, NFTData.NFTId, NFTData.nftAddress, NFTData.paymentId,msg.sender);
    }
    
    //get NFT details from OrdereId
    function getNFTDetails(uint _orderId) external view returns (nftsData memory) {
        return setNFTsData[_orderId];
    }

    //get NFT status from orderId
    function nftsStatus(uint _orderId) external view returns (OrderStatus) {
        return NFT_Status[_orderId];
    }

    function paymentGateway(IERC20 wallet,address from , address to , uint fee) private {
        wallet.transferFrom(from,to,fee);
    }

    function isValidPaymentId(uint _paymentId) private pure {
        require(_paymentId > 0 && _paymentId < 5,"Invalid Paayment Token Id");
    }

    function isValidPrice(uint _value) private pure {
        require(_value >= 10 ,"Invalid Price");
    }
    function isValidValue(uint _value) private pure {
        require(_value !=0 ,"Invalid NFT Id");
    }

    function transferNFT(IERC721 nftAddress,address from , address to, uint _NFTId) private {
        nftAddress.safeTransferFrom(from,to,_NFTId);
    }

}