// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, StdUtils} from "forge-std/Test.sol";
import {VolunteerFactory} from "../src/Factory.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {IVolunteer} from "../src/interface/IVolunteer.sol";

contract FactoryTest is Test {
    VolunteerFactory internal factory;
    MockERC721 internal nft;
    MockERC20 internal token;
    address internal volunteer;
    IVolunteer public iv;

    function setUp() public {
        factory = new VolunteerFactory();
        nft = new MockERC721("Test NFT", "TNFT");
        token = new MockERC20("Money", "MNE", 18);
        volunteer = factory.deployTokenDistributor(token, nft, address(this));
        iv = IVolunteer(volunteer);
    }

    function testDeploy() public {
        volunteer = factory.deployTokenDistributor(token, nft, address(this));
        assertEq(factory.getDeployedTokenDistributor(address(this)), volunteer);
        // assertEq(factory.getDeployedVolunteerNFT(address(this)), volunteer);
    }

    function testVolunteerContractCallsSuccessfully() public view {
        address token_address = iv.getToken();
        assertEq(token_address, address(token));
    }

    function testAddressWhiteListedSuccessfully() public {
        address[] memory whitelist = new address[](6);
        for (uint256 i = 0; i < 6; i++) {
            // for (uint j = 1; j < 7; j++){
            whitelist[i] = vm.addr(i + 1);
            // }
        }

        iv.whitelistAddresses(whitelist);

        address[] memory returnedArray = iv.getWhitelistedAddresses();
        uint256 arrLength = returnedArray.length;
        assertEq(arrLength, 6);
    }

    function testRemoveFromWhitelist() public {
        address[] memory whitelist = new address[](2);
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);
        whitelist[0] = user1;
        whitelist[1] = user2;

        iv.whitelistAddresses(whitelist);
        address[] memory returnedArray = iv.getWhitelistedAddresses();
        uint256 arrLength = returnedArray.length;
        assertEq(arrLength, 2);

        iv.removeFromWhitelist(user1);
        bool isWhitelisted = iv.isWhitelisted(user1);
        assertEq(isWhitelisted, false);
    }

    function testUpdateWhitelist() public {
        address[] memory whitelist = new address[](2);
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);
        whitelist[0] = user1;
        whitelist[1] = user2;

        iv.whitelistAddresses(whitelist);
        address[] memory returnedArray = iv.getWhitelistedAddresses();
        uint256 arrLength = returnedArray.length;
        assertEq(arrLength, 2);

        address user3 = vm.addr(3);
        iv.updateWhitelist(user3);
        returnedArray = iv.getWhitelistedAddresses();
        arrLength = returnedArray.length;
        assertEq(arrLength, 3);
    }
}
