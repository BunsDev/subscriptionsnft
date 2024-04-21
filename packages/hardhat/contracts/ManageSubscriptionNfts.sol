// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LoyaltyNFTManager is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct User {
        bool exists;
        uint256[] ownedNFTs;
    }

    struct LoyaltyNFTData {
        uint256 loyaltyPoints;
        uint256 expirationDate;
        string metadataURI;
        bool isClaimed;
    }

    mapping(address => User) private _users;
    mapping(uint256 => LoyaltyNFTData) private _loyaltyNFTData;

    event UserCreated(address indexed user);
    event UserDeleted(address indexed user);
    event LoyaltyNFTCreated(uint256 indexed tokenId, address indexed creator, string metadataURI);
    event LoyaltyNFTClaimed(uint256 indexed tokenId, address indexed claimer);
    event LoyaltyNFTTransferred(uint256 indexed tokenId, address indexed from, address indexed to);

    constructor() ERC721("LoyaltyNFT", "LNFT") {}

    function createUser(address user) public {
        require(!_users[user].exists, "User already exists");
        _users[user].exists = true;
        emit UserCreated(user);
    }

    function deleteUser(address user) public {
        require(_users[user].exists, "User does not exist");
        delete _users[user];
        emit UserDeleted(user);
    }

    function createLoyaltyNFT(address user, uint256 loyaltyPoints, uint256 expirationDate, string memory metadataURI) public {
        require(_users[user].exists, "User does not exist");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(user, tokenId);
        _loyaltyNFTData[tokenId] = LoyaltyNFTData(loyaltyPoints, expirationDate, metadataURI, false);
        _users[user].ownedNFTs.push(tokenId);

        emit LoyaltyNFTCreated(tokenId, user, metadataURI);
    }

    function claimLoyaltyNFT(uint256 tokenId) public {
        require(_users[msg.sender].exists, "User does not exist");
        require(!_loyaltyNFTData[tokenId].isClaimed, "Loyalty NFT already claimed");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not approved or owner");

        _loyaltyNFTData[tokenId].isClaimed = true;
        _users[msg.sender].ownedNFTs.push(tokenId);

        emit LoyaltyNFTClaimed(tokenId, msg.sender);
    }

    function transferLoyaltyNFT(address to, uint256 tokenId) public {
        require(_users[msg.sender].exists, "User does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not approved or owner");

        _transfer(msg.sender, to, tokenId);
        _removeNFTFromUser(msg.sender, tokenId);
        _users[to].ownedNFTs.push(tokenId);

        emit LoyaltyNFTTransferred(tokenId, msg.sender, to);
    }

    function getUserOwnedNFTs(address user) public view returns (uint256[] memory) {
        require(_users[user].exists, "User does not exist");
        return _users[user].ownedNFTs;
    }

    function getLoyaltyNFTData(uint256 tokenId) public view returns (uint256, uint256, string memory, bool) {
        require(_exists(tokenId), "Loyalty NFT does not exist");
        LoyaltyNFTData memory data = _loyaltyNFTData[tokenId];
        return (data.loyaltyPoints, data.expirationDate, data.metadataURI, data.isClaimed);
    }

    function _removeNFTFromUser(address user, uint256 tokenId) private {
        uint256[] storage ownedNFTs = _users[user].ownedNFTs;
        for (uint256 i = 0; i < ownedNFTs.length; i++) {
            if (ownedNFTs[i] == tokenId) {
                ownedNFTs[i] = ownedNFTs[ownedNFTs.length - 1];
                ownedNFTs.pop();
                break;
            }
        }
    }
}