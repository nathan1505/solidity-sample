// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract NFT is Ownable, ERC721A {
  using Strings for uint256;
  using Counters for Counters.Counter;
  
  Counters.Counter private supply;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 101;
  uint256 public publicSale = 80;
  uint256 public maxMintAmount = 3;
  uint256 public mintTime = 9999999999;
  uint256 public mintWhitelistTime = 9999999999;
  uint256 public mintWhitelistTimeEnd = 9999999999;
  bool public paused = false;
  address public admin;

  bytes32 public merkleRoot = 0x00c399d05892fed83511687da967ca88576f0d730e29343ef582014ef72eebef;
  mapping(address => bool) whitelistedClaimed;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    admin = msg.sender;
    _safeMint(admin, 1);
  }

  modifier mintComplicance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount");
    require(supply.current() + _mintAmount <= maxSupply, "All sold out");
    require(!paused, "Minting is paused");
    _;
  }

  // public
  function mint(uint256 _mintAmount) public payable mintComplicance(_mintAmount){
    require(block.timestamp >= mintTime, "The mint has not started yet");
    require(supply.current() + _mintAmount <= publicSale, "Public sold out");
    require(msg.value >= cost * _mintAmount, "Not enough ether");

    _safeMint(msg.sender, _mintAmount);
  }

  // mint for whitelist
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintComplicance(_mintAmount){
    require(block.timestamp >= mintWhitelistTime, "The whitelist mint has not started yet");
    require(block.timestamp <= mintWhitelistTimeEnd, "The whitelist mint is over");
    require(whitelistedClaimed[msg.sender] == false, "User is not in whitelist or already minted once");
    require(supply.current() + _mintAmount <= publicSale, "Public sold out");
    require(msg.value >= cost * _mintAmount, "Not enough ether");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof.");

    _safeMint(msg.sender, _mintAmount);
    whitelistedClaimed[msg.sender] = true;

  }

  //Exclusive for team
  function teamMint(uint256 _mintAmount) public payable {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount");
    _safeMint(msg.sender, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
      "ERC721AMetadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //only owner
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
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

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMintTime(uint unixtime) public onlyOwner(){
	  mintTime = unixtime;
  }

  function setWhitelistMintTime(uint unixtime) public onlyOwner(){
	  mintWhitelistTime = unixtime;
  }

  function setWhitelistMintTimeEnd(uint unixtime) public onlyOwner(){
	  mintWhitelistTimeEnd = unixtime;
  }

  function setPublicSale(uint256 sale) public onlyOwner(){
    publicSale = sale;
  }

  function setMerkleRoot(bytes32 m) public onlyOwner(){
    merkleRoot = m;
  }

  function checkPublicSale() public view returns (uint){
      return publicSale;
  }

  function checkWhitelisteStatus(bytes32[] calldata _merkleProof, address _address) public view returns (bool){
      bytes32 leaf = keccak256(abi.encodePacked(_address));
	  return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function checkSupply() public view returns (uint){
	  return maxSupply - totalSupply();
  }

  function checkMintTime() public view returns (uint256){
	  return mintTime;
  }

  function checkWhitelistMintTime() public view returns (uint256){
	  return mintWhitelistTime;
  }

  function checkWhitelistMintTimeEnd() public view returns (uint256){
	  return mintWhitelistTimeEnd;
  }

  function checkTimeNow() public view returns (uint256){
	  return block.timestamp;
  }
}