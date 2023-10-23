// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Asset} from "./IERC7527Agency.sol";

/**
 * @dev The settings of the agency.
 * @param implementation The address of the agency implementation.
 * @param asset The parameter of asset of the agency.
 * @param immutableData The immutable data are stored in the code region of the created proxy contract of agencyImplementation.
 * @param initData If init data is not empty, calls proxy contract of agencyImplementation with this data.
 */
struct AgencySettings {
    address payable implementation;
    Asset asset;
    bytes immutableData;
    bytes initData;
}

/**
 * @dev The settings of the app.
 * @param implementation The address of the app implementation.
 * @param immutableData The immutable data are stored in the code region of the created proxy contract of appImplementation.
 * @param initData If init data is not empty, calls proxy contract of appImplementation with this data.
 */
struct AppSettings {
    address implementation;
    bytes immutableData;
    bytes initData;
}

interface IERC7527Factory {
    /**
     * @dev Deploys a new agency and app clone and initializes both.
     * @param agencySettings The settings of the agency.
     * @param appSettings The settings of the app.
     * @param data The data is additional data, it has no specified format and it is sent in call to `factory`.
     * @return appInstance The address of the created proxy contract of appImplementation.
     * @return agencyInstance The address of the created proxy contract of agencyImplementation.
     */
    function deployWrap(AgencySettings calldata agencySettings, AppSettings calldata appSettings, bytes calldata data)
        external
        returns (address, address);
}
