// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test, StdUtils} from "forge-std/Test.sol";
// import { Vm } from "forge-std/Vm.sol";
import {Utilities} from "./utils/Utilities.sol";
import {TokenDistributor} from "../src/Volunteer.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";

contract TokenDistributorTest is Test {
    Utilities internal utils;
    TokenDistributor internal distributor;
    MockERC20 internal token;
    MockERC721 internal nft;

    address payable[] internal users;
    address user0;
    address user1;
    address internal user2;
    address owner;

    function setUp() public {
        // Create users
        user0 = vm.addr(2);
        user1 = vm.addr(3);
        user2 = vm.addr(4);

        token = new MockERC20("Test Token", "TT", 18);
        nft = new MockERC721("Test NFT", "TNFT");
        owner = vm.addr(1);

        distributor = new TokenDistributor(token, nft, owner);

        // Mint some tokens to the distributor for testing
        token.mint(address(distributor), 1000 ether);
    }

    function testDistributeTokensToWhitelistedAddresses() public {
        // Whitelist users[0] and users[1]
        address[] memory addresses = new address[](2);
        addresses[0] = user0;
        addresses[1] = user1;
        vm.startPrank(owner);
        distributor.whitelistAddresses(addresses);

        // Mint NFTs to the whitelisted users
        nft.mint(user0, 1);
        nft.mint(user1, 2);

        // Distribute tokens equally among whitelisted users
        distributor.distributeTokens();
        vm.stopPrank();

        // Check balances
        assertEq(token.balanceOf(user0), 500 ether);
        assertEq(token.balanceOf(user1), 500 ether);
    }

    // function testCannotDistributeToNonWhitelisted() public {
    //     // Whitelist only users[0]

    //     // Attempt to distribute tokens to a non-whitelisted address
    //     vm.expectRevert("Address not whitelisted");
    //     distributor.distributeTokens(200 ether);
    // }

    function testCannotDistributeWithoutNFT() public {
        // Whitelist user1 but do not mint NFT
        address[] memory addresses = new address[](2);
        addresses[0] = user0;
        addresses[1] = user1;
        vm.startPrank(owner);
        distributor.whitelistAddresses(addresses);
        nft.mint(user0, 1);

        // Attempt to distribute tokens to a user without an NFT
        distributor.distributeTokens();
        vm.stopPrank();
        assertTrue(token.balanceOf(user1) < 500);
    }

    function testCannotDistributeToNonWhitelisted() public {
        // Whitelist users[0] and users[1]
        address[] memory addresses = new address[](3);
        addresses[0] = user0;
        addresses[1] = user1;
        addresses[2] = user2;

        vm.startPrank(owner);
        distributor.whitelistAddresses(addresses);

        // Mint NFTs to the whitelisted users
        nft.mint(user0, 1);
        nft.mint(user1, 2);
        nft.mint(user2, 3);

        uint256 balancePerUser = token.balanceOf(address(distributor)) / addresses.length;

        // remove user2 from whitelist
        distributor.removeFromWhitelist(user2);

        // Attempt to distribute more tokens than available
        distributor.distributeTokens();
        vm.stopPrank();
        assertTrue(token.balanceOf(user2) < balancePerUser);
    }

    function testCannotAddInvalidTokenAddress() public {
        // Whitelist user1 but do not mint NFT
        address[] memory addresses = new address[](2);
        addresses[0] = user0;
        addresses[1] = user1;
        vm.startPrank(owner);
        distributor.whitelistAddresses(addresses);

        // Attempt to add invalid token address
        vm.expectRevert("Invalid token address");
        distributor.addTokenAddress(address(0));
    }
}
