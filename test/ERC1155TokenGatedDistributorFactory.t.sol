// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC1155TokenGatedDistributorFactory} from "../src/ERC1155TokenGatedDistributorFactory.sol";
import {ERC1155TokenGatedDistributor} from "../src/ERC1155TokenGatedDistributor.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";

contract ERC1155TokenGatedDistributorFactoryTest is Test {
    ERC1155TokenGatedDistributorFactory factory;
    MockERC20 rewardToken;
    
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    
    string baseURI = "https://example.com/metadata/";
    uint256 baseFee = 10 ether;
    
    function setUp() public {
        vm.startPrank(owner);
        factory = new ERC1155TokenGatedDistributorFactory();
        rewardToken = new MockERC20("Reward Token", "RWD", 18);
        vm.stopPrank();
    }
    
    function test_DeployDistributor() public {
        vm.startPrank(owner);
        address payable distributorAddress = payable(factory.deployDistributor(
            baseURI,
            user1,
            address(rewardToken),
            baseFee
        ));
        vm.stopPrank();
        
        // Verify distributor was deployed
        assertTrue(distributorAddress != address(0));
        
        // Verify distributor is tracked in factory
        assertTrue(factory.isDistributor(distributorAddress));
        assertEq(factory.deployedDistributors(0), distributorAddress);
        assertEq(factory.getDistributorCount(), 1);
        
        // Verify distributor properties using low-level calls instead of direct casting
        (bool success1, bytes memory data1) = distributorAddress.staticcall(
            abi.encodeWithSignature("owner()")
        );
        require(success1, "Call to owner() failed");
        address retrievedOwner = abi.decode(data1, (address));
        assertEq(retrievedOwner, user1);
        
        (bool success2, bytes memory data2) = distributorAddress.staticcall(
            abi.encodeWithSignature("rewardToken()")
        );
        require(success2, "Call to rewardToken() failed");
        address retrievedToken = abi.decode(data2, (address));
        assertEq(retrievedToken, address(rewardToken));
        
        (bool success3, bytes memory data3) = distributorAddress.staticcall(
            abi.encodeWithSignature("getBaseFee()")
        );
        require(success3, "Call to getBaseFee() failed");
        uint256 retrievedBaseFee = abi.decode(data3, (uint256));
        assertEq(retrievedBaseFee, baseFee);
    }
    
    function test_DeployMultipleDistributors() public {
        vm.startPrank(owner);
        
        // Deploy first distributor
        address distributor1 = factory.deployDistributor(
            baseURI,
            user1,
            address(rewardToken),
            baseFee
        );
        
        // Deploy second distributor
        address distributor2 = factory.deployDistributor(
            "https://another-uri.com/",
            user2,
            address(rewardToken),
            baseFee * 2
        );
        
        vm.stopPrank();
        
        // Verify both distributors are tracked
        assertEq(factory.getDistributorCount(), 2);
        assertTrue(factory.isDistributor(distributor1));
        assertTrue(factory.isDistributor(distributor2));
        
        // Verify getAllDistributors returns both addresses
        address[] memory allDistributors = factory.getAllDistributors();
        assertEq(allDistributors.length, 2);
        assertEq(allDistributors[0], distributor1);
        assertEq(allDistributors[1], distributor2);
    }
    
    function test_GetDistributorsPaginated() public {
        vm.startPrank(owner);
        
        // Deploy 5 distributors
        address[] memory deployedAddresses = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            // Fix the address calculation
            address userAddress = address(uint160(uint256(uint160(user1)) + i));
            deployedAddresses[i] = factory.deployDistributor(
                string(abi.encodePacked(baseURI, vm.toString(i))),
                userAddress,
                address(rewardToken),
                baseFee + i
            );
        }
        
        vm.stopPrank();
        
        // Test pagination with different parameters
        address[] memory page1 = factory.getDistributorsPaginated(0, 2);
        assertEq(page1.length, 2);
        assertEq(page1[0], deployedAddresses[0]);
        assertEq(page1[1], deployedAddresses[1]);
        
        address[] memory page2 = factory.getDistributorsPaginated(2, 2);
        assertEq(page2.length, 2);
        assertEq(page2[0], deployedAddresses[2]);
        assertEq(page2[1], deployedAddresses[3]);
        
        address[] memory lastPage = factory.getDistributorsPaginated(4, 2);
        assertEq(lastPage.length, 1);
        assertEq(lastPage[0], deployedAddresses[4]);
    }
    
    function test_GetDistributorsByOwner() public {
        vm.startPrank(owner);
        
        // Deploy distributors with different owners
        factory.deployDistributor(baseURI, user1, address(rewardToken), baseFee);
        factory.deployDistributor(baseURI, user2, address(rewardToken), baseFee);
        factory.deployDistributor(baseURI, user1, address(rewardToken), baseFee);
        
        vm.stopPrank();
        
        // Get distributors by owner
        address[] memory user1Distributors = factory.getDistributorsByOwner(user1);
        assertEq(user1Distributors.length, 2);
        
        address[] memory user2Distributors = factory.getDistributorsByOwner(user2);
        assertEq(user2Distributors.length, 1);
    }
    
    function test_VerifyDistributor() public {
        vm.startPrank(owner);
        
        // Deploy a distributor
        address distributorAddress = factory.deployDistributor(
            baseURI,
            user1,
            address(rewardToken),
            baseFee
        );
        
        vm.stopPrank();
        
        // Verify a valid distributor
        assertTrue(factory.verifyDistributor(distributorAddress));
        
        // Verify an invalid distributor
        assertFalse(factory.verifyDistributor(address(0x123)));
    }
    
    function test_RevertWhenInvalidOwnerAddress() public {
        vm.startPrank(owner);
        
        // Try to deploy with zero address as owner
        vm.expectRevert("Invalid owner address");
        factory.deployDistributor(
            baseURI,
            address(0),
            address(rewardToken),
            baseFee
        );
        
        vm.stopPrank();
    }
    
    function test_RevertWhenPaginationOutOfBounds() public {
        vm.startPrank(owner);
        
        // Deploy a distributor
        factory.deployDistributor(
            baseURI,
            user1,
            address(rewardToken),
            baseFee
        );
        
        vm.stopPrank();
        
        // Try to get distributors with out of bounds start index
        vm.expectRevert("Start index out of bounds");
        factory.getDistributorsPaginated(1, 1);
    }
} 