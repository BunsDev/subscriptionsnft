// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SubscriptionNfts is ERC721 {
    address public owner;
    uint256 public tokenIdCounter;

    struct NFT {
        uint256 id;
        string metadata;
    }

    struct User {
        address walletAddress;
        uint256[] nftIds;
    }

    struct NFTStore {
        address owner;
        mapping(uint256 => NFT) nfts;
        mapping(address => User) users;
    }

    mapping(uint256 => NFTStore) public stores;

    event NFTCreated(uint256 indexed storeId, uint256 indexed nftId, string metadata);
    event UserCreated(uint256 indexed storeId, address indexed walletAddress);
    event NFTDistributed(uint256 indexed storeId, address indexed recipient, uint256 indexed nftId);
    event StoreCreated(uint256 indexed storeId, address indexed owner);
    event StoreRemoved(uint256 indexed storeId);
    event UserRemoved(uint256 indexed storeId, address indexed walletAddress);

    constructor() ERC721("LoyaltyNFTStore", "LOYALTYNFTS") {
        owner = msg.sender;
        tokenIdCounter = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function createStore(address _owner) external {
        require(_owner != address(0), "Invalid store owner address");
        uint256 newStoreId = tokenIdCounter++;
        NFTStore storage newStore = stores[newStoreId];
        newStore.owner = _owner;
        emit StoreCreated(newStoreId, _owner);
    }

    function removeStore(uint256 _storeId) external onlyOwner {
        require(stores[_storeId].owner != address(0), "Store does not exist");
        delete stores[_storeId];
        emit StoreRemoved(_storeId);
    }

    function createNFT(uint256 _storeId, string memory _metadata) external onlyOwner {
        require(stores[_storeId].owner != address(0), "Store does not exist");
        uint256 newNFTId = tokenIdCounter;
        stores[_storeId].nfts[newNFTId] = NFT(newNFTId, _metadata);
        emit NFTCreated(_storeId, newNFTId, _metadata);
    }

    function createUser(uint256 _storeId) external {
        address walletAddress = msg.sender;
        require(stores[_storeId].users[walletAddress].walletAddress == address(0), "User already exists");
        stores[_storeId].users[walletAddress] = User(walletAddress, new uint256[](0));
        emit UserCreated(_storeId, walletAddress);
    }

    function removeUser(uint256 _storeId, address _userAddress) external onlyOwner {
        require(stores[_storeId].owner != address(0), "Store does not exist");
        require(stores[_storeId].users[_userAddress].walletAddress != address(0), "User does not exist");
        delete stores[_storeId].users[_userAddress];
        emit UserRemoved(_storeId, _userAddress);
    }

    function distributeNFT(uint256 _storeId, address _recipient, uint256 _nftId) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(stores[_storeId].nfts[_nftId].id != 0, "NFT does not exist");
        
        stores[_storeId].users[_recipient].nftIds.push(_nftId);
        emit NFTDistributed(_storeId, _recipient, _nftId);
    }

    function checkNFTOwnership(uint256 _storeId, address _userAddress, uint256 _nftId) external view returns (bool) {
        require(_userAddress != address(0), "Invalid user address");
        require(stores[_storeId].nfts[_nftId].id != 0, "NFT does not exist");

        for (uint256 i = 0; i < stores[_storeId].users[_userAddress].nftIds.length; i++) {
            if (stores[_storeId].users[_userAddress].nftIds[i] == _nftId) {
                return true;
            }
        }

        return false;
    }
}
