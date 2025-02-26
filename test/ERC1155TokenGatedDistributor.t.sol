// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {ERC1155TokenGatedDistributor} from "../src/ERC1155TokenGatedDistributor.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";

contract ERC1155TokenGatedDistributorTest is Test {
    ERC1155TokenGatedDistributor internal distributor;
    MockERC20 internal rewardToken;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal user3;

    uint256 internal constant BASE_FEE = 10 ether;
    uint256 internal constant PROOF_OF_ENGAGEMENT = 2;
    uint256 internal constant PROOF_OF_ATTENDANCE = 1;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        vm.startPrank(owner);
        rewardToken = new MockERC20("Reward Token", "RWD", 18);
        distributor = new ERC1155TokenGatedDistributor(
            "https://example.com/",
            owner,
            address(rewardToken),
            BASE_FEE
        );
        vm.stopPrank();
    }

    // Mint and Distribution Tests
    function test_MintProofOfEngagement() public {
        vm.prank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        
        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 5);
        assertEq(distributor.getHolderCount(), 1);
    }

    function test_DistributeTokens() public {
        // Prepare tokens and mint NFTs
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), 1000 ether);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 3);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 2);
        vm.stopPrank();

        // Distribute tokens
        vm.prank(owner);
        distributor.distributeTokens();

        // Check token distributions
        assertEq(rewardToken.balanceOf(user1), 3 * BASE_FEE);
        assertEq(rewardToken.balanceOf(user2), 2 * BASE_FEE);
    }

    function test_RevertDistribution_NoTokens() public {
        vm.prank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 3);

        vm.expectRevert("No tokens available for distribution");
        vm.prank(owner);
        distributor.distributeTokens();
    }

    function test_RevertDistribution_NoEligibleRecipients() public {
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), 1000 ether);
        distributor.mint(user1, PROOF_OF_ATTENDANCE, 3);
        vm.stopPrank();

        vm.expectRevert("No eligible recipients");
        vm.prank(owner);
        distributor.distributeTokens();
    }

    // Holder Management Tests
    function test_HolderTracking() public {
        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 3);
        vm.stopPrank();

        assertEq(distributor.getHolderCount(), 2);
    }

    function test_HolderRemoval() public {
        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 3);
        distributor.burn(user1, PROOF_OF_ENGAGEMENT, 5);
        vm.stopPrank();

        assertEq(distributor.getHolderCount(), 1);
    }

    // Owner Function Tests
    function test_SetRewardToken() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18);
        
        vm.prank(owner);
        distributor.setRewardToken(address(newToken));
        assertEq(distributor.getRewardToken(), address(newToken));

        vm.expectRevert("Invalid token address");
        vm.prank(owner);
        distributor.setRewardToken(address(0));
    }

    function test_SetBaseFee() public {
        uint256 newBaseFee = 20 ether;
        
        vm.prank(owner);
        distributor.setBaseFee(newBaseFee);
        
        assertEq(distributor.getBaseFee(), newBaseFee);
        
        // Test the distribution with new base fee
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), 100 ether);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 2);
        vm.stopPrank();
        
        vm.prank(owner);
        distributor.distributeTokens();
        
        // User should receive tokens based on the new base fee
        assertEq(rewardToken.balanceOf(user1), 2 * newBaseFee);
    }

    // Access Control Tests
    function test_RevertNonOwnerMint() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(user1);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 3);
    }

    function test_RevertNonOwnerBurn() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(user1);
        distributor.burn(user2, PROOF_OF_ENGAGEMENT, 3);
    }

    // Fuzzing Tests
    function testFuzz_MintAndDistribute(uint256 amount) public {
        vm.assume(amount > 0 && amount < 100);
        
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), amount * BASE_FEE);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, amount);
        vm.stopPrank();

        vm.prank(owner);
        distributor.distributeTokens();

        assertEq(rewardToken.balanceOf(user1), amount * BASE_FEE);
    }
} 