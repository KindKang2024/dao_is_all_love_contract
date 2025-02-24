// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IMinUNSRegistry } from
  "../../contracts/dependencies/IMinUNSRegistry.sol";

contract UnsRegistryMock is IMinUNSRegistry {
  mapping(uint256 => address) private tokenIdToOwner;

  constructor(string[] memory initialLabels, address initialOwner) {
    require(initialOwner != address(0), "Registry: INVALID_OWNER");
    require(initialLabels.length > 0, "Registry: LABELS_EMPTY");

    // Set the initial owner and domain
    (uint256 tokenId,) = _namehash(initialLabels);
    tokenIdToOwner[tokenId] = initialOwner;
  }

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`. ERC721 related function.
   */
  function ownerOf(
    uint256 tokenId
  ) external view returns (address) {
    return tokenIdToOwner[tokenId];
  }

  // Function to set the owner of a token (for testing)
  function setOwner(string[] memory labels, address owner) external {
    (uint256 tokenId,) = _namehash(labels);
    tokenIdToOwner[tokenId] = owner;
  }

  function namehash(
    string[] calldata labels
  ) external pure override returns (uint256 hash) {
    (hash,) = _namehash(labels);
  }

  function _namehash(
    string[] memory labels
  ) internal pure returns (uint256 tokenId, uint256 parentId) {
    for (uint256 i = labels.length; i > 0; i--) {
      parentId = tokenId;
      tokenId = _namehash(parentId, labels[i - 1]);
    }
  }

  function _namehash(
    uint256 tokenId,
    string memory label
  ) internal pure returns (uint256) {
    require(bytes(label).length != 0, "Registry: LABEL_EMPTY");
    return uint256(
      keccak256(abi.encodePacked(tokenId, keccak256(abi.encodePacked(label))))
    );
  }
}
