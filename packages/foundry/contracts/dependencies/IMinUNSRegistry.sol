// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

interface IMinUNSRegistry {
    /**
     * @dev Returns the owner of the NFT specified by `tokenId`. ERC721 related function.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Provides namehashe of the provided domain labels.
     * @param labels array of domain labels splitted by '.' (for `aaa.bbb.crypto` it will be [`aaa`, `bbb`, `crypto`])
     */
    function namehash(string[] calldata labels) external pure returns (uint256);
}
