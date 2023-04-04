// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultiMarketplace is ERC721Holder,ERC1155Holder,ReentrancyGuard  {
    uint256 orderId = 1;
    uint256 public constant platformFee = 10;
    address immutable owner;
    constructor(){
        owner = msg.sender;
    }

    //Events
    event NFTsStatus (uint indexed _orderId, uint indexed _NFTId,address indexed _nftAddress, uint _paymentId, address _owner);
    event paymentMethods (uint indexed _paymentId, IERC20 indexed _paymentTokens);  

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
        address nftAddress;
        address owner;
    }
    
    //mapping orderId to nftsData
    mapping(uint => nftsData) private setNFTsData;

    //mapping id to token Addresses
    mapping(uint => IERC20) public paymentTokens;

    //mapping orderId to OrderStaus
    mapping(uint => OrderStatus) private NFT_Status;

    //ensure to use payment Id once
    mapping(uint => bool) private payMethodAdded;
     
    //set Payment methods
    function setPaymentTokens(uint _paymentId,IERC20 _paymentToken) external{
        require(msg.sender == owner,"only Owner allowed");
        require(!payMethodAdded[_paymentId], "PaymentId already added");
        require(address(_paymentToken) != address(0),"invalid TokenAddress");
        isValidPaymentId(_paymentId);
        paymentTokens[_paymentId] = _paymentToken;
        payMethodAdded[_paymentId] = true;
        emit paymentMethods(_paymentId, _paymentToken);
    }

    //list ERC721 /ERC1155 NFTs
    function listForSale(uint _NFTId, uint _nftPrice , uint _paymentId, address _nftAddress) external nonReentrant  {
        isValidValue(_NFTId);
        isValidPrice(_nftPrice);
        isValidPaymentId(_paymentId);
        require(address(_nftAddress) != address(0),"invalid NFT address");
        bool isERC721 = IERC721(_nftAddress).supportsInterface(0x80ac58cd); 
        bool isERC1155 = IERC1155(_nftAddress).supportsInterface(0xd9b67a26);
        NFT_Status[orderId] = OrderStatus.Open;
        setNFTsData[orderId] = nftsData(_NFTId, _nftPrice,_paymentId, _nftAddress, msg.sender);
        
        if(isERC721){
            orderId++;
            transfer721Token(_nftAddress,msg.sender,address(this),_NFTId);
        }
        else if(isERC1155){
            orderId++;
            transfer1155Token(_nftAddress,msg.sender ,address(this), _NFTId);
        }
        else {
            revert ("Invalid NFT aaddress");
        }
        emit NFTsStatus(orderId, _NFTId, _nftAddress, _paymentId, msg.sender); 
    }
     
    //cancel listed NFTs
    function cancelListing(uint _orderId) external nonReentrant {
        nftsData memory NFTData = setNFTsData[_orderId];
        require(NFTData.NFTId !=0, "Invalid OrderId");
        require(msg.sender == setNFTsData[_orderId].owner, "only Owner can cancel Listing");
        require(NFT_Status[orderId] == OrderStatus.Open,"NFT Not For Sale");
        NFT_Status[_orderId] = OrderStatus.Cancelled;
        bool isERC721 = IERC721(NFTData.nftAddress).supportsInterface(0x80ac58cd); 
        bool isERC1155 = IERC1155(NFTData.nftAddress).supportsInterface(0xd9b67a26);
       if(isERC721){
            transfer721Token(NFTData.nftAddress,address(this),msg.sender,NFTData.NFTId);
        }
        else if(isERC1155){
            transfer1155Token(NFTData.nftAddress,address(this),msg.sender, NFTData.NFTId);
        }
        emit NFTsStatus(_orderId, NFTData.NFTId, NFTData.nftAddress, NFTData.paymentId,NFTData.owner);
        delete setNFTsData[_orderId];
        
    }
    
    //Buy Listed Nfts
    function buyNFts(uint _orderId) external nonReentrant  {
        nftsData memory NFTData = setNFTsData[_orderId];
        require(NFT_Status[orderId] == OrderStatus.Open,"NFT Not For Sale");
        require(msg.sender != NFTData.owner, "owner can't buy");
        uint256 marketplaceFee = NFTData.NFTprice /platformFee; 
        uint256 payToOwner = NFTData.NFTprice - marketplaceFee;
        paymentGateway(paymentTokens[NFTData.paymentId], msg.sender, address(this),marketplaceFee);
        paymentGateway(paymentTokens[NFTData.paymentId], msg.sender, NFTData.owner,payToOwner);
        bool isERC721 = IERC721(NFTData.nftAddress).supportsInterface(0x80ac58cd); 
        bool isERC1155 = IERC1155(NFTData.nftAddress).supportsInterface(0xd9b67a26);
        NFT_Status[_orderId] = OrderStatus.Filled;
        if(isERC721){
            transfer721Token(NFTData.nftAddress,address(this),msg.sender,NFTData.NFTId);
        }
        else if(isERC1155){
            transfer1155Token(NFTData.nftAddress,address(this),msg.sender, NFTData.NFTId);
        }
        emit NFTsStatus(_orderId, NFTData.NFTId, NFTData.nftAddress, NFTData.paymentId,NFTData.owner);
        delete setNFTsData[_orderId];
        
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

    function transfer721Token(address nftAddress,address from , address to, uint _NFTId) private {
        IERC721(nftAddress).safeTransferFrom(from,to,_NFTId);
    }

    function transfer1155Token(address nftAddress,address from , address to, uint _id) private {
        IERC1155(nftAddress).safeTransferFrom(from,to,_id,1,"");
    }


}