// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC7527App {
    /**
     * @dev Returns the maximum supply of the non-fungible token.
     */
    function getMaxSupply() external view returns (uint256);

    /**
     * @dev Returns the name of the non-fungible token with identifier `id`.
     * @param id The identifier of the non-fungible token.
     */
    function getName(uint256 id) external view returns (string memory);

    /**
     * @dev Returns the agency of the non-fungible token.
     */
    function getAgency() external view returns (address payable);

    /**
     * @dev Sets the agency of the non-fungible token.
     * @param agency The agency of the non-fungible token.
     */
    function setAgency(address payable agency) external;

    /**
     * @dev Mints a non-fungible token to `to`.
     * @param to The address of the recipient of the newly created non-fungible token.
     * @param data The data to encode into the newly created non-fungible token.
     */
    function mint(address to, bytes calldata data) external returns (uint256);

    /**
     * @dev Burns a non-fungible token with identifier `tokenId`.
     * @param tokenId The identifier of the non-fungible token to burn.
     * @param data The data to encode into the non-fungible token with identifier `tokenId`.
     */
    function burn(uint256 tokenId, bytes calldata data) external;
}
