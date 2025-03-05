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

    function test_BurnTokensAfterDistribution() public {
        // Setup initial state
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), 100 * BASE_FEE);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 3);
        vm.stopPrank();

        // Record initial balances
        uint256 user1InitialBalance = distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT);
        uint256 user2InitialBalance = distributor.balanceOf(user2, PROOF_OF_ENGAGEMENT);
        
        // Distribute tokens
        vm.prank(owner);
        distributor.distributeTokens();

        // Verify tokens were burned
        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 0, "User1's tokens should be burned");
        assertEq(distributor.balanceOf(user2, PROOF_OF_ENGAGEMENT), 0, "User2's tokens should be burned");
        
        // Verify holder count is updated
        assertEq(distributor.getHolderCount(), 0, "All holders should be removed after distribution");
    }

    function test_PartialBurnOnDistribution() public {
        // Setup: Mint more tokens than will be distributed
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), 5 * BASE_FEE); // Only enough for 5 tokens
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 10); // Mint 10 tokens
        vm.stopPrank();

        // Record initial balance
        uint256 initialBalance = distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT);
        assertEq(initialBalance, 10, "Initial balance should be 10");

        // Distribute tokens - should revert due to insufficient funds
        vm.prank(owner);
        vm.expectRevert("Insufficient funds");
        distributor.distributeTokens();

        // Verify no tokens were burned due to revert
        assertEq(
            distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT),
            initialBalance,
            "Tokens should not be burned on failed distribution"
        );
    }

    function test_MultipleBurnsInSingleDistribution() public {
        // Setup multiple holders with different amounts
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), 1000 * BASE_FEE);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 3);
        distributor.mint(user3, PROOF_OF_ENGAGEMENT, 7);
        vm.stopPrank();

        // Record initial state
        uint256[] memory initialBalances = new uint256[](3);
        initialBalances[0] = distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT);
        initialBalances[1] = distributor.balanceOf(user2, PROOF_OF_ENGAGEMENT);
        initialBalances[2] = distributor.balanceOf(user3, PROOF_OF_ENGAGEMENT);
        
        // Verify initial balances
        assertEq(initialBalances[0], 5, "User1 initial balance incorrect");
        assertEq(initialBalances[1], 3, "User2 initial balance incorrect");
        assertEq(initialBalances[2], 7, "User3 initial balance incorrect");

        // Distribute and burn tokens
        vm.prank(owner);
        distributor.distributeTokens();

        // Verify all tokens were burned
        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 0, "User1's tokens not burned");
        assertEq(distributor.balanceOf(user2, PROOF_OF_ENGAGEMENT), 0, "User2's tokens not burned");
        assertEq(distributor.balanceOf(user3, PROOF_OF_ENGAGEMENT), 0, "User3's tokens not burned");

        // Verify holder count is updated
        assertEq(distributor.getHolderCount(), 0, "Holder count should be 0 after distribution");

        // Verify reward token distribution
        assertEq(rewardToken.balanceOf(user1), 5 * BASE_FEE, "User1 reward incorrect");
        assertEq(rewardToken.balanceOf(user2), 3 * BASE_FEE, "User2 reward incorrect");
        assertEq(rewardToken.balanceOf(user3), 7 * BASE_FEE, "User3 reward incorrect");
    }

    function test_HolderCountBeforeAndAfterDistribution() public {
        // Setup initial holders
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), 100 * BASE_FEE);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 2);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 3); 
        distributor.mint(user3, PROOF_OF_ENGAGEMENT, 1);
        vm.stopPrank();

        // Verify initial holder count
        assertEq(distributor.getHolderCount(), 3, "Initial holder count should be 3");

        // Distribute tokens which burns the PROOF_OF_ENGAGEMENT tokens
        vm.prank(owner);
        distributor.distributeTokens();

        // Verify holder count is 0 after distribution since all tokens were burned
        assertEq(distributor.getHolderCount(), 0, "Holder count should be 0 after distribution");

        // Verify individual balances are also 0
        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 0);
        assertEq(distributor.balanceOf(user2, PROOF_OF_ENGAGEMENT), 0);
        assertEq(distributor.balanceOf(user3, PROOF_OF_ENGAGEMENT), 0);
    }
} 