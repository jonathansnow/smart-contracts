// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract CheapSpaceFly is ERC721, Ownable {
  using Strings for uint256;
  using SafeMath for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;

  string public baseURI;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 1;

  bool public saleActive = false;
  bool public whitelistActive = false;

  mapping(address => bool) public whitelist;
  mapping(address => uint256) public addressMintedBalance;

  constructor(address[] memory addresses) ERC721("CheapSpaceFly", "SSF") {
    setBaseURI("ipfs://QmQxTmCi2sXecN4wi4KQKWcfUXesAFnGHKNUGDE4oi5t1e/");

    // Set up initial whitelist
    for (uint256 i = 0; i < addresses.length; i++) {
        updateWhitelist(addresses[i]);
    }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // Public sale mint function
  function mint(address _to, uint256 _mintAmount) public payable {
    require(saleActive, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT"); // May be overkill, unlikely and not a problem if 0
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(_tokenSupply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");

    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
    require(msg.value >= cost.mul(_mintAmount), "insufficient funds");

    for (uint256 i = 0; i < _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _tokenSupply.increment();
      _safeMint(_to, _tokenSupply.current());
    }
  }

  // Public whitelist mint function
  function whitelistMint(address _to, uint256 _mintAmount) public payable {
    require(whitelistActive, "whitelist mint not active");
    require(isWhitelisted(msg.sender), "no whitelist tokens to mint");
    require(_mintAmount > 0, "need to mint at least 1 NFT"); // May be overkill, unlikely and not a problem if 0
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(_tokenSupply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
    require(msg.value >= cost.mul(_mintAmount), "insufficient funds");

    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
    require(msg.value >= cost.mul(_mintAmount), "insufficient funds");

    for (uint256 i = 0; i < _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _tokenSupply.increment();
      _safeMint(_to, _tokenSupply.current());
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  // Function to return the number of NFTs an address is whitelisted for
  function isWhitelisted(address userAddress) public view returns (bool)  {
      return whitelist[userAddress];
  } 

  // Function to display the total supply from Counter
  function totalSupply() public view returns (uint256) {
      return _tokenSupply.current();
  }

  //only owner

  // Function to alllow the contract owner to mint NFTs
  function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
    require(_tokenSupply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
    // Add in additional owner mint logic here if needed

    for (uint256 i = 0; i < _mintAmount; i++) {
      _tokenSupply.increment();
      _safeMint(_to, _tokenSupply.current());
    }
  }

  // Function to whitelist a user
  function updateWhitelist(address userAddress) public onlyOwner {
    whitelist[userAddress] = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function toggleSale() public onlyOwner {
    saleActive = !saleActive;
  }
  
  function toggleWhitelist() public onlyOwner {
    whitelistActive = !whitelistActive;
  }
 
  function withdrawBalance() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
