// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VolunteerFactory} from "../src/Factory.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {IVolunteer} from "../src/interface/IVolunteer.sol";

contract FactoryTest is Test {
    VolunteerFactory internal factory;
    MockERC20 internal token;
    MockERC1155 internal nft1155;
    address internal volunteer;
    IVolunteer internal iv;
    address internal owner;
    uint256 internal constant BASE_FEE = 5 ether; // 5 tokens per NFT

    event VolunteerDeployed(address indexed owner, address indexed volunteerAddress);

    function setUp() public {
        owner = makeAddr("owner");
        factory = new VolunteerFactory();
        token = new MockERC20("Test Token", "TT", 18);
        nft1155 = new MockERC1155("Test NFT 1155", address(this));
        
        vm.prank(owner);
        volunteer = factory.deployTokenDistributor(
            address(token),
            nft1155,
            BASE_FEE
        );
        iv = IVolunteer(volunteer);
    }

    function test_DeploymentSuccess() public {
        assertEq(iv.getToken(), address(token));
        assertEq(iv.getNFTAddress(), address(nft1155));
        assertEq(iv.getBaseFee(), BASE_FEE);
    }

    function test_DeploymentWithZeroAddressFails() public {
        vm.expectRevert("Invalid token address");
        factory.deployTokenDistributor(
            address(0),
            nft1155,
            BASE_FEE
        );

        vm.expectRevert("Invalid NFT contract");
        factory.deployTokenDistributor(
            address(token),
            MockERC1155(address(0)),
            BASE_FEE
        );
    }

    function test_MultipleDeployments() public {
        address[] memory deployments = new address[](3);
        
        for(uint256 i = 0; i < 3; i++) {
            address newOwner = makeAddr(string(abi.encodePacked("owner", i)));
            vm.prank(newOwner);
            deployments[i] = factory.deployTokenDistributor(
                address(token),
                nft1155,
                BASE_FEE
            );
            
            assertEq(IVolunteer(deployments[i]).getToken(), address(token));
            assertEq(IVolunteer(deployments[i]).getNFTAddress(), address(nft1155));
        }

        // Ensure all deployments are unique
        assertFalse(deployments[0] == deployments[1]);
        assertFalse(deployments[1] == deployments[2]);
        assertFalse(deployments[0] == deployments[2]);
    }

    function test_DeploymentWithDifferentTokens() public {
        MockERC20 newToken = new MockERC20("New Token", "NT", 18);
        
        vm.prank(owner);
        address newVolunteer = factory.deployTokenDistributor(
            address(newToken),
            nft1155,
            BASE_FEE
        );

        assertEq(IVolunteer(newVolunteer).getToken(), address(newToken));
        assertNotEq(IVolunteer(newVolunteer).getToken(), address(token));
    }

    function test_DeploymentWithDifferentBaseFees() public {
        uint256 newBaseFee = 10 ether;
        
        vm.prank(owner);
        address newVolunteer = factory.deployTokenDistributor(
            address(token),
            nft1155,
            newBaseFee
        );

        assertEq(IVolunteer(newVolunteer).getBaseFee(), newBaseFee);
        assertNotEq(IVolunteer(newVolunteer).getBaseFee(), BASE_FEE);
    }

    function testFuzz_DeploymentWithDifferentBaseFees(uint256 _baseFee) public {
        vm.assume(_baseFee > 0 && _baseFee < type(uint256).max);
        
        vm.prank(owner);
        address newVolunteer = factory.deployTokenDistributor(
            address(token),
            nft1155,
            _baseFee
        );

        assertEq(IVolunteer(newVolunteer).getBaseFee(), _baseFee);
    }
}
