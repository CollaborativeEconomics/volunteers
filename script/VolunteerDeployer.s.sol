// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {TokenDistributor} from "../src/Volunteer.sol";
import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import {console} from "forge-std/console.sol";

contract VolunteerDeployer is Script {
    function run() external returns (TokenDistributor) {
        // Read environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address ownerAddress = vm.envAddress("OWNER_ADDRESS");
        address nftContractAddress = vm.envAddress("NFT_CONTRACT_ADDRESS");
        uint256 baseFee = vm.envUint("BASE_FEE");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Volunteer contract
        TokenDistributor tokenDistributor =
            new TokenDistributor(
                tokenAddress, 
                ownerAddress, 
                ERC1155(nftContractAddress), 
                baseFee,
                "Token Distributor v1"
            );

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployed address
        console.log("TokenDistributor deployed at:", address(tokenDistributor));

        return tokenDistributor;
    }
}
