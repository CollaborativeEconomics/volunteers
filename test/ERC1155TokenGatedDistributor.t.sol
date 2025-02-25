// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC1155TokenGatedDistributor} from "../src/ERC1155TokenGatedDistributor.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";

contract ERC1155TokenGatedDistributorTest is Test {
    ERC1155TokenGatedDistributor internal distributor;
    MockERC20 internal rewardToken;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal user3;

    uint256 internal constant BASE_FEE = 1 ether;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy mock reward token
        rewardToken = new MockERC20("Reward Token", "RWD", 18);
        
        // Deploy distributor
        distributor = new ERC1155TokenGatedDistributor(
            "ipfs://",
            owner,
            address(rewardToken),
            BASE_FEE
        );

        // Fund distributor with reward tokens
        rewardToken.mint(address(distributor), 1000 ether);
    }

    function testMinting() public {
        distributor.mint(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        assertEq(distributor.balanceOf(user1, distributor.PROOF_OF_ENGAGEMENT()), 1);
    }

    function testGetEligibleHolders() public {
        distributor.mint(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        distributor.mint(user2, distributor.PROOF_OF_ENGAGEMENT(), 1);
        distributor.mint(user3, distributor.PROOF_OF_ATTENDANCE(), 1);

        address[] memory holders = distributor.getEligibleHolders();
        assertEq(holders.length, 2);
        assertTrue(holders[0] == user1 || holders[1] == user1);
        assertTrue(holders[0] == user2 || holders[1] == user2);
    }

    function testDistributeTokens() public {
        // Mint POE tokens
        distributor.mint(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        distributor.mint(user2, distributor.PROOF_OF_ENGAGEMENT(), 1);

        // Initial balances should be 0
        assertEq(rewardToken.balanceOf(user1), 0);
        assertEq(rewardToken.balanceOf(user2), 0);

        // Distribute tokens
        distributor.distributeTokens();

        // Check final balances - each holder should get BASE_FEE
        assertEq(rewardToken.balanceOf(user1), BASE_FEE);
        assertEq(rewardToken.balanceOf(user2), BASE_FEE);
    }

    function testFailDistributeWithInsufficientBalance() public {
        // Deploy new distributor with insufficient balance
        ERC1155TokenGatedDistributor emptyDistributor = new ERC1155TokenGatedDistributor(
            "ipfs://",
            owner,
            address(rewardToken),
            BASE_FEE
        );

        // Mint some tokens but not enough for distribution
        rewardToken.mint(address(emptyDistributor), BASE_FEE - 1);
        
        emptyDistributor.mint(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        emptyDistributor.mint(user2, distributor.PROOF_OF_ENGAGEMENT(), 1);
        
        vm.expectRevert("Insufficient funds");
        emptyDistributor.distributeTokens();
    }

    function testHolderTracking() public {
        // Test adding holders
        distributor.mint(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        address[] memory holders = distributor.getEligibleHolders();
        assertEq(holders.length, 1);
        assertEq(holders[0], user1);

        distributor.mint(user2, distributor.PROOF_OF_ENGAGEMENT(), 1);
        holders = distributor.getEligibleHolders();
        assertEq(holders.length, 2);

        // Test removing holders
        distributor.burn(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        holders = distributor.getEligibleHolders();
        assertEq(holders.length, 1);
        assertEq(holders[0], user2);
    }

    function testHolderTrackingWithTransfers() public {
        // Initial mint
        distributor.mint(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        
        // Transfer to user2
        vm.prank(user1);
        distributor.safeTransferFrom(user1, user2, distributor.PROOF_OF_ENGAGEMENT(), 1, "");

        // Check holder tracking updated
        address[] memory holders = distributor.getEligibleHolders();
        assertEq(holders.length, 1);
        assertEq(holders[0], user2);
        
        // Transfer back to user1
        vm.prank(user2);
        distributor.safeTransferFrom(user2, user1, distributor.PROOF_OF_ENGAGEMENT(), 1, "");
        
        holders = distributor.getEligibleHolders();
        assertEq(holders.length, 1);
        assertEq(holders[0], user1);
    }

    function testOnlyTracksPOEHolders() public {
        distributor.mint(user1, distributor.PROOF_OF_ATTENDANCE(), 1);
        address[] memory holders = distributor.getEligibleHolders();
        assertEq(holders.length, 0, "Should not track POA holders");

        distributor.mint(user1, distributor.PROOF_OF_ENGAGEMENT(), 1);
        holders = distributor.getEligibleHolders();
        assertEq(holders.length, 1, "Should track POE holders");
    }

    function testFailInvalidTokenId() public {
        distributor.mint(user1, 3, 1); // Invalid token ID
    }

    function testUpdateBaseFee() public {
        uint256 newBaseFee = 2 ether;
        distributor.setBaseFee(newBaseFee);
        assertEq(distributor.baseFee(), newBaseFee);
    }

    function testChangeRewardToken() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18);
        distributor.setRewardToken(address(newToken));
        assertEq(distributor.rewardToken(), address(newToken));
    }

    function testWithdrawRewardTokens() public {
        uint256 initialBalance = rewardToken.balanceOf(address(distributor));
        distributor.withdrawRewardTokens();
        assertEq(rewardToken.balanceOf(owner), initialBalance);
        assertEq(rewardToken.balanceOf(address(distributor)), 0);
    }

    receive() external payable {}
} 