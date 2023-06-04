// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

abstract contract POAP is ERC721{
    function tokenOfOwnerByIndex(address, uint256) public virtual;
    function tokenEvent(uint256) public virtual returns (uint256);
}

contract GlobalAttendanceScore is ERC721, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    event ReviewCreated(address author, uint256 poapTokenId, uint256 eventId, uint256 newTokenId);

    Counters.Counter private _tokenIds;
    mapping (uint256 => string) private _tokenURIs;
    mapping (uint256 => uint256) private _eventIds;
    mapping (uint256 => uint256) private _poapTokenIds;
    mapping (uint256 => address) private _reviewerAddresses;

    address proxyPOAPAddress = 0x22C1f6050E56d2876009903609a2cC3fEf83B415;
    POAP POAPContract = POAP(payable(proxyPOAPAddress));

    constructor() ERC721("Global Attendance Score", "GAS") payable {
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function eventByTokenId(uint256 tokenId) public view returns (uint256){
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        return _eventIds[tokenId];
    }

    function poapByTokenId(uint256 tokenId) public view returns (uint256){
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        return _poapTokenIds[tokenId];
    }

    function reviewCreator(uint256 tokenId) public view returns (address){
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        return _reviewerAddresses[tokenId];
    }

    function mint(uint256 eventId,uint256 poapTokenId, string memory metadataURI, bytes memory signature, address to) public returns (uint256){
        require(POAPContract.ownerOf(poapTokenId) == msg.sender, "Caller is not owner of POAP.");
        require(POAPContract.tokenEvent(poapTokenId) == eventId, "POAP does not correspond to Event.");
        require(SignatureChecker.isValidSignatureNow(owner(),keccak256(abi.encodePacked(metadataURI)).toEthSignedMessageHash(),signature), "Token URI not signed correctly.");
        uint256 newTokenId = _tokenIds.current();
        _mint(to,newTokenId);
        _setTokenURI(newTokenId, metadataURI);
        _eventIds[newTokenId] = eventId;
        _poapTokenIds[newTokenId] = poapTokenId;
        _reviewerAddresses[newTokenId] = msg.sender;
        _tokenIds.increment();
        emit ReviewCreated(msg.sender, poapTokenId, eventId, newTokenId);
        return newTokenId;
    }
}
