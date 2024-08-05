// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenDistributor} from "./Volunteer.sol";
import {VolunteerNFT} from "./VolunteerNFT.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

contract VolunteerFactory {
    mapping(address => address) public deployedTokenDistributors;
    mapping(address => address) public deployedVolunteersNFT;

    event VolunteerDeployed(address indexed owner, address indexed volunteerAddress);

    function deployTokenDistributor(ERC20 _token, ERC721 _nftContract, address owner) external returns (address) {
        TokenDistributor token_distributor = new TokenDistributor(_token, _nftContract, owner);
        deployedTokenDistributors[msg.sender] = address(token_distributor);
        emit VolunteerDeployed(msg.sender, address(token_distributor));
        return address(token_distributor);
    }

    function deployVolunteerNFT(string memory name, string memory symbol, address owner) external returns (address) {
        VolunteerNFT volunteer_nft = new VolunteerNFT(name, symbol, owner);
        deployedVolunteersNFT[msg.sender] = address(volunteer_nft);
        emit VolunteerDeployed(msg.sender, address(volunteer_nft));
        return address(volunteer_nft);
    }

    function getDeployedTokenDistributor(address owner) external view returns (address) {
        return deployedTokenDistributors[owner];
    }

    function getDeployedVolunteerNFT(address owner) external view returns (address) {
        return deployedVolunteersNFT[owner];
    }
}
