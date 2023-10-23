// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev The settings of the agency.
 * @param currency The address of the currency. If `currency` is 0, the currency is Ether.
 * @param premium The base premium of the currency.
 * @param feeRecipient The address of the fee recipient.
 * @param mintFeePercent The fee of minting.
 * @param burnFeePercent The fee of burning.
 */
struct Asset {
    address currency;
    uint256 premium;
    address feeRecipient;
    uint16 mintFeePercent;
    uint16 burnFeePercent;
}

interface IERC7527Agency {
    /**
     * @dev Allows the account to receive Ether
     *
     * Accounts MUST implement a `receive` function.
     *
     * Accounts MAY perform arbitrary logic to restrict conditions
     * under which Ether can be received.
     */
    receive() external payable;

    /**
     * @dev Emitted when `tokenId` token is wrapped.
     * @param to The address of the recipient of the newly created non-fungible token.
     * @param tokenId The identifier of the newly created non-fungible token.
     * @param price The price of wrapping.
     * @param fee The fee of wrapping.
     */
    event Wrap(address indexed to, uint256 indexed tokenId, uint256 price, uint256 fee);

    /**
     * @dev Emitted when `tokenId` token is unwrapped.
     * @param to The address of the recipient of the currency.
     * @param tokenId The identifier of the non-fungible token to unwrap.
     * @param price The price of unwrapping.
     * @param fee The fee of unwrapping.
     */
    event Unwrap(address indexed to, uint256 indexed tokenId, uint256 price, uint256 fee);

    /**
     * @dev Wrap currency premium into a non-fungible token.
     * @param to The address of the recipient of the newly created non-fungible token.
     * @param data The data to encode into ifself and the newly created non-fungible token.
     * @return The identifier of the newly created non-fungible token.
     */
    function wrap(address to, bytes calldata data) external payable returns (uint256);

    /**
     * @dev Unwrap a non-fungible token into currency premium.
     *
     * Todo: event
     *
     * @param to The address of the recipient of the currency.
     * @param tokenId The identifier of the non-fungible token to unwrap.
     * @param data The data to encode into ifself and the non-fungible token with identifier `tokenId`.
     */
    function unwrap(address to, uint256 tokenId, bytes calldata data) external payable;

    /**
     * @dev Returns the strategy of the agency.
     * @return app The address of the app.
     * @return asset The asset of the agency.
     * @return attributeData The attributeData of the agency.
     */
    function getStrategy() external view returns (address app, Asset memory asset, bytes memory attributeData);

    /**
     * @dev Returns the price and fee of unwrapping.
     * @param data The data to encode to calculate the price and fee of unwrapping.
     * @return price The price of wrapping.
     * @return fee The fee of wrapping.
     */
    function getUnwrapOracle(bytes memory data) external view returns (uint256 price, uint256 fee);

    /**
     * @dev Returns the price and fee of wrapping.
     * @param data The data to encode to calculate the price and fee of wrapping.
     * @return price The price of wrapping.
     * @return fee The fee of wrapping.
     */
    function getWrapOracle(bytes memory data) external view returns (uint256 price, uint256 fee);
}
