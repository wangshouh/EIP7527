// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC7527Agency, ERC7527App, ERC7527Factory} from "../src/ERC7527.sol";
import {IERC7527App} from "../src/interfaces/IERC7527App.sol";
import {IERC7527Agency, Asset} from "../src/interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "../src/interfaces/IERC7527Factory.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract ImplementationScript is Script {
    function run() public returns (ERC7527Agency agency, ERC7527App app, IERC7527Factory factory) {
        vm.startBroadcast();
        agency = new ERC7527Agency();
        app = new ERC7527App();
        factory = new ERC7527Factory();
        vm.stopBroadcast();
    }
}

contract AgenctWithAppScript is Script {
    Asset public asset;
    AgencySettings public agencySettings;
    AppSettings public appSettings;

    address public agency;
    address public app;
    address public factory;

    function setUp() public {
        agency = address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        app = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        factory = address(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

        asset = Asset({
            currency: address(0),
            basePremium: 0.1 ether,
            feeRecipient: address(1),
            mintFeePercent: uint16(10),
            burnFeePercent: uint16(10)
        });

        agencySettings = AgencySettings({
            implementation: payable(agency),
            asset: asset,
            immutableData: bytes(""),
            initData: bytes("")
        });

        appSettings = AppSettings({implementation: app, immutableData: bytes(""), initData: bytes("")});
    }

    function run() public returns (address cloneAgency, address cloneApp) {
        vm.startBroadcast();
        (cloneApp, cloneAgency) = IERC7527Factory(factory).deployWrap(agencySettings, appSettings, bytes(""));
        vm.stopBroadcast();
    }
}
