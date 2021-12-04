// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract CheapSpaceFly is ERC721, Ownable {
  using Strings for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;

  string public baseURI;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 1;
  bool public salePaused = true;
  bool public onlyAllowlisted = true;
  address[] public allowlistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

  constructor() ERC721("CheapSpaceFly", "SSF") {
    setBaseURI("ipfs://QmQxTmCi2sXecN4wi4KQKWcfUXesAFnGHKNUGDE4oi5t1e/");
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    require(!salePaused, "the contract is paused");
    uint256 supply = _tokenSupply.current();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyAllowlisted == true) {
            require(isAllowlisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _tokenSupply.increment();
      _safeMint(_to, supply + i);
    }
  }

  function isAllowlisted(address _user) public view returns (bool) {
    for (uint i = 0; i < allowlistedAddresses.length; i++) {
      if (allowlistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
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

  //only owner
  
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
    salePaused = !salePaused;
  }
  
  function setOnlyAllowlisted(bool _state) public onlyOwner {
    onlyAllowlisted = _state;
  }
  
  function allowlistUsers(address[] calldata _users) public onlyOwner {
    delete allowlistedAddresses;
    allowlistedAddresses = _users;
  }
 
  function withdrawBalance() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
