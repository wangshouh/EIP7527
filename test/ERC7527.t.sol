// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC7527Agency, ERC7527App, ERC7527Factory} from "../src/ERC7527.sol";
import {IERC7527App} from "../src/interfaces/IERC7527App.sol";
import {IERC7527Agency, Asset} from "../src/interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "../src/interfaces/IERC7527Factory.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract ERC7527Test is Test {
    ERC7527Agency public agency;
    ERC7527App public app;

    ERC7527Factory public factory;

    ERC7527WarpReentrancy public warpReentrancy;

    address public appDeployAddress;
    address public agencyDeployAddress;

    function setUp() public {
        agency = new ERC7527Agency();
        app = new ERC7527App();

        factory = new ERC7527Factory();

        Asset memory asset = Asset({
            currency: address(0),
            premium: 0.1 ether,
            feeRecipient: address(1),
            mintFeePercent: uint16(10),
            burnFeePercent: uint16(10)
        });

        AgencySettings memory agencySettings = AgencySettings({
            implementation: payable(address(agency)),
            asset: asset,
            immutableData: bytes(""),
            initData: bytes("")
        });

        AppSettings memory appSettings =
            AppSettings({implementation: address(app), immutableData: bytes(""), initData: bytes("")});

        (appDeployAddress, agencyDeployAddress) = factory.deployWrap(agencySettings, appSettings, bytes(""));

        warpReentrancy = new ERC7527WarpReentrancy(agencyDeployAddress);
    }

    function testWarp() public {
        vm.deal(address(this), 1 ether);
        IERC7527Agency(payable(agencyDeployAddress)).wrap{value: 0.5 ether}(address(this), abi.encode(uint256(1)));

        assertEq(IERC721Enumerable(appDeployAddress).totalSupply(), uint256(1));
        assertEq(IERC721Enumerable(appDeployAddress).ownerOf(1), address(this));
        assertEq(agencyDeployAddress.balance, uint256(0.1 ether));
        assertEq(address(1).balance, uint256(0.0001 ether));
        assertEq(address(this).balance, uint256(1 ether - 0.1001 ether));
    }

    function testUnwarp() public {
        vm.deal(address(this), 1 ether);
        IERC7527Agency(payable(agencyDeployAddress)).wrap{value: 0.5 ether}(address(this), abi.encode(uint256(1)));
        IERC7527Agency(payable(agencyDeployAddress)).unwrap(address(this), 1, bytes(""));

        assertEq(IERC721Enumerable(appDeployAddress).totalSupply(), uint256(0));
        assertEq(address(this).balance, uint256(0.9998 ether));
        assertEq(address(1).balance, uint256(0.0002 ether));
    }

    function testWarpReentrancy() public {
        vm.deal(address(warpReentrancy), 1 ether);
        vm.expectRevert(0x1425ea42);
        warpReentrancy.warpNFT();
    }

    receive() external payable {}
}

contract ERC7527WarpReentrancy {
    address public agencyDeployAddress;
    uint256 public assetId = 1;

    constructor (address agency) {
        agencyDeployAddress = agency;
    }

    function warpNFT() public {
        IERC7527Agency(payable(agencyDeployAddress)).wrap{value: 0.5 ether}(address(this), abi.encode(uint256(1)));
    }

    receive() external payable {
        if (assetId <= 3) {
            assetId += 1;
            IERC7527Agency(payable(agencyDeployAddress)).wrap{value: 0.3 ether}(address(this), abi.encode(assetId));
        }
    }

}