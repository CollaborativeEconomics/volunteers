// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test, StdUtils} from "forge-std/Test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {TokenDistributor} from "../src/Volunteer.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";

contract TokenDistributorTest is Test {
    Utilities internal utils;
    TokenDistributor internal distributor;
    MockERC20[] internal tokens;
    MockERC721 internal nft;
    MockERC1155 internal nft1155;

    address payable[] internal users;
    address[] internal addresses;
    address user0;
    address user1;
    address internal user2;
    address owner;

    function setUp() public {
        // Create users
        user0 = vm.addr(2);
        user1 = vm.addr(3);
        user2 = vm.addr(4);

        tokens = new MockERC20[](2);
        tokens[0] = new MockERC20("Test Token", "TT", 18);
        tokens[1] = new MockERC20("Test Token 2", "TT2", 18);
        address[] memory tokensAddress = new address[](2);
        tokensAddress[0] = address(tokens[0]);
        tokensAddress[1] = address(tokens[1]);
        nft = new MockERC721("Test NFT", "TNFT");
        nft1155 = new MockERC1155("Test NFT 1155", address(this));
        owner = vm.addr(1);

        distributor = new TokenDistributor(tokensAddress[0], owner, nft1155, 5 ether);

        // Mint some tokens to the distributor for testing
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].mint(address(distributor), 1000 ether);
        }
    }

    modifier initial_operation {
       addresses[0] = user0;
        addresses[1] = user1;
        addresses[2] = user2;

        vm.startPrank(owner);
        distributor.whitelistAddresses(addresses);

        // Mint NFTs to the whitelisted users
        nft.mint(user0, 1);
        nft.mint(user1, 2);
        nft.mint(user2, 3);
        _;
    }


    function testCannotAddInvalidTokenAddress() public{
        // Whitelist user1 but do not mint NFT
        // address[] memory addresses = new address[](2);
        // addresses[0] = user0;
        // addresses[1] = user1;
        vm.startPrank(owner);
        // Attempt to add invalid token address
        vm.expectRevert("Invalid token address");
        distributor.changeTokenAddress(address(0));
    }

    function testDistributeTokensWithNFT() public {
        // Whitelist users[0] and users[1]
        address[] memory addresses = new address[](2);
        addresses[0] = user0;
        addresses[1] = user1;
        vm.startPrank(owner);
        distributor.whitelistAddresses(addresses);

        // Mint NFTs to the whitelisted users
        nft1155.mint(user0, 2, 1, "");
        nft1155.mint(user1, 2, 3, "");

        // Distribute tokens equally among whitelisted users
        distributor.distributeTokensByUnit(addresses);
        vm.stopPrank();

        // Check balances
        assertEq(tokens[0].balanceOf(user0), 5 ether, "User0 balance is incorrect");
        assertEq(tokens[0].balanceOf(user1), 15 ether, "User1 balance is incorrect");
    }

    function testCannotDistributeWithNoRecipients() public {
        address[] memory emptyAddresses = new address[](0);
        vm.startPrank(owner);
        vm.expectRevert("No recipients provided");
        distributor.distributeTokensByUnit(emptyAddresses);
        vm.stopPrank();
    }

    function testCannotDistributeWithNoTokenBalance() public {
        // Create new distributor with no tokens
        TokenDistributor newDistributor = new TokenDistributor(address(tokens[0]), owner, nft1155, 5 ether);
        
        address[] memory addresses = new address[](1);
        addresses[0] = user0;
        
        vm.startPrank(owner);
        newDistributor.whitelistAddresses(addresses);
        nft1155.mint(user0, 2, 1, "");
        
        vm.expectRevert("No tokens available for distribution");
        newDistributor.distributeTokensByUnit(addresses);
        vm.stopPrank();
    }

    function testCannotDistributeWithNoEligibleRecipients() public {
        address[] memory addresses = new address[](2);
        addresses[0] = user0;
        addresses[1] = user1;
        
        vm.startPrank(owner);
        // Whitelist but don't mint NFTs
        distributor.whitelistAddresses(addresses);
        
        vm.expectRevert("No eligible recipients");
        distributor.distributeTokensByUnit(addresses);
        vm.stopPrank();
    }

    function testCannotDistributeWhenNoTokensActuallySent() public {
        address[] memory addresses = new address[](2);
        addresses[0] = user0;
        addresses[1] = user1;
        
        vm.startPrank(owner);
        // Whitelist users
        distributor.whitelistAddresses(addresses);
        
        // Mint NFTs but set base fee to 0
        distributor.updateBaseFee(0);
        nft1155.mint(user0, 2, 1, "");
        nft1155.mint(user1, 2, 1, "");
        
        vm.expectRevert("No tokens were distributed");
        distributor.distributeTokensByUnit(addresses);
        vm.stopPrank();
    }

    function testCannotDistributeToNonWhitelisted() public {
        address[] memory addresses = new address[](1);
        addresses[0] = user0;
        
        vm.startPrank(owner);
        // Mint NFT but don't whitelist
        nft1155.mint(user0, 2, 1, "");
        
        vm.expectRevert("No eligible recipients");
        distributor.distributeTokensByUnit(addresses);
        vm.stopPrank();
    }
}
