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

    // ERC1155 Standard Tests
    function test_SafeTransferFrom() public {
        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        vm.stopPrank();

        vm.startPrank(user1);
        distributor.setApprovalForAll(user2, true);
        vm.stopPrank();

        vm.prank(user2);
        distributor.safeTransferFrom(user1, user3, PROOF_OF_ENGAGEMENT, 3, "");

        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 2);
        assertEq(distributor.balanceOf(user3, PROOF_OF_ENGAGEMENT), 3);
    }

    function test_SafeBatchTransferFrom() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = PROOF_OF_ENGAGEMENT;
        ids[1] = PROOF_OF_ATTENDANCE;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 3;

        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.mint(user1, PROOF_OF_ATTENDANCE, 3);
        vm.stopPrank();

        vm.startPrank(user1);
        distributor.setApprovalForAll(user2, true);
        vm.stopPrank();

        vm.prank(user2);
        distributor.safeBatchTransferFrom(user1, user3, ids, amounts, "");

        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 0);
        assertEq(distributor.balanceOf(user1, PROOF_OF_ATTENDANCE), 0);
        assertEq(distributor.balanceOf(user3, PROOF_OF_ENGAGEMENT), 5);
        assertEq(distributor.balanceOf(user3, PROOF_OF_ATTENDANCE), 3);
    }

    function test_ApprovalForAll() public {
        vm.prank(user1);
        distributor.setApprovalForAll(user2, true);
        assertTrue(distributor.isApprovedForAll(user1, user2));

        vm.prank(user1);
        distributor.setApprovalForAll(user2, false);
        assertFalse(distributor.isApprovedForAll(user1, user2));
    }

    function test_BalanceOfBatch() public {
        address[] memory accounts = new address[](3);
        accounts[0] = user1;
        accounts[1] = user2;
        accounts[2] = user3;

        uint256[] memory ids = new uint256[](3);
        ids[0] = PROOF_OF_ENGAGEMENT;
        ids[1] = PROOF_OF_ENGAGEMENT;
        ids[2] = PROOF_OF_ATTENDANCE;

        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.mint(user2, PROOF_OF_ENGAGEMENT, 3);
        distributor.mint(user3, PROOF_OF_ATTENDANCE, 2);
        vm.stopPrank();

        uint256[] memory balances = distributor.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 5);
        assertEq(balances[1], 3);
        assertEq(balances[2], 2);
    }

    // URI Tests
    function test_TokenURI() public {
        string memory engagementURI = distributor.uri(PROOF_OF_ENGAGEMENT);
        string memory attendanceURI = distributor.uri(PROOF_OF_ATTENDANCE);
        
        assertEq(engagementURI, string(abi.encodePacked("ipfs://", vm.toString(PROOF_OF_ENGAGEMENT))));
        assertEq(attendanceURI, string(abi.encodePacked("ipfs://", vm.toString(PROOF_OF_ATTENDANCE))));
    }

    // MAX_HOLDERS Tests
    function test_RevertMaxHoldersReached() public {
        // Create many holders up to MAX_HOLDERS - 1
        for(uint256 i = 0; i < 9999; i++) {
            address holder = address(uint160(i + 1000)); // Start from non-zero address
            vm.prank(owner);
            distributor.mint(holder, PROOF_OF_ENGAGEMENT, 1);
        }

        // This should succeed as it's the last allowed holder
        vm.prank(owner);
        distributor.mint(address(uint160(10999)), PROOF_OF_ENGAGEMENT, 1);

        // This should fail as we've reached MAX_HOLDERS
        vm.expectRevert("Max holders reached");
        vm.prank(owner);
        distributor.mint(address(uint160(11000)), PROOF_OF_ENGAGEMENT, 1);
    }

    // withdrawRewardTokens Tests
    function test_WithdrawRewardTokens() public {
        uint256 amount = 1000 ether;
        vm.startPrank(owner);
        rewardToken.mint(address(distributor), amount);
        distributor.withdrawRewardTokens();
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(owner), amount);
        assertEq(rewardToken.balanceOf(address(distributor)), 0);
    }

    function test_RevertUnauthorizedWithdraw() public {
        vm.prank(owner);
        rewardToken.mint(address(distributor), 1000 ether);

        vm.expectRevert("UNAUTHORIZED");
        vm.prank(user1);
        distributor.withdrawRewardTokens();
    }

    // Edge Cases
    function test_ZeroAmountOperations() public {
        // Zero amount mint
        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 0);
        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 0);
        assertEq(distributor.getHolderCount(), 0);

        // Zero amount burn
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.burn(user1, PROOF_OF_ENGAGEMENT, 0);
        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 5);
        vm.stopPrank();
    }

    function test_TransferBetweenHolders() public {
        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        vm.stopPrank();

        vm.prank(user1);
        distributor.safeTransferFrom(user1, user2, PROOF_OF_ENGAGEMENT, 3, "");

        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 2);
        assertEq(distributor.balanceOf(user2, PROOF_OF_ENGAGEMENT), 3);
        assertEq(distributor.getHolderCount(), 2);
    }

    function test_MixedTokenTransfers() public {
        vm.startPrank(owner);
        distributor.mint(user1, PROOF_OF_ENGAGEMENT, 5);
        distributor.mint(user1, PROOF_OF_ATTENDANCE, 3);
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        ids[0] = PROOF_OF_ENGAGEMENT;
        ids[1] = PROOF_OF_ATTENDANCE;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 1;

        vm.prank(user1);
        distributor.safeBatchTransferFrom(user1, user2, ids, amounts, "");

        assertEq(distributor.balanceOf(user1, PROOF_OF_ENGAGEMENT), 3);
        assertEq(distributor.balanceOf(user1, PROOF_OF_ATTENDANCE), 2);
        assertEq(distributor.balanceOf(user2, PROOF_OF_ENGAGEMENT), 2);
        assertEq(distributor.balanceOf(user2, PROOF_OF_ATTENDANCE), 1);
        assertEq(distributor.getHolderCount(), 2);
    }
} 