// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {Volunteer} from "../src/Volunteer.sol";

contract VolunteerDeployer is Script {
    function run() external returns (Volunteer) {
        // Read environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address ownerAddress = vm.envAddress("OWNER_ADDRESS");
        address nftContractAddress = vm.envAddress("NFT_CONTRACT_ADDRESS");
        uint256 baseFee = vm.envUint("BASE_FEE");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Volunteer contract
        Volunteer volunteer = new Volunteer(
            tokenAddress,
            ownerAddress,
            ERC1155(nftContractAddress),
            baseFee
        );

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployed address
        console.log("Volunteer deployed at:", address(volunteer));

        return volunteer;
    }
}