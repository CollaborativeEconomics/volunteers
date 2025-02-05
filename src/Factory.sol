// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenDistributor} from "./Volunteer.sol";
import {VolunteerNFT} from "./VolunteerNFT.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";

/**
 * @title VolunteerFactory
 * @author Lawal Abubakar
 * @dev A contract for deploying TokenDistributor and VolunteerNFT contracts
 */
contract VolunteerFactory {
    string public constant NAME = "Volunteer Factory v1";

    /**
     * @dev Mapping of deployed token distributors by owner address
     */
    mapping(address owner => address tokenDistributor) public deployedTokenDistributors;
    /**
     * @dev Mapping of deployed VolunteerNFTs by owner address
     */
    mapping(address deployer => address NFTAddress) public deployedVolunteersNFT;

    event VolunteerDeployed(address indexed owner, address indexed volunteerAddress); // @dev Event emitted when a volunteer contract is deployed

    /**
     * @dev Deploys a new TokenDistributor contract
     * @param _token The donation accepted token address
     * @param _nftContract The ERC721 contract used for NFT ownership checks
     * @param _baseFee The token baseFee
     * @param _name The name of the deployed contract
     * @return The address of the newly deployed TokenDistributor
     */
    function deployTokenDistributor(
        address _token, 
        ERC1155 _nftContract, 
        uint256 _baseFee,
        string memory _name
    ) external returns (address) {
        TokenDistributor token_distributor = new TokenDistributor(
            _token, 
            msg.sender, 
            _nftContract, 
            _baseFee,
            _name
        );
        deployedTokenDistributors[msg.sender] = address(token_distributor); // @dev Store the deployed contract address
        emit VolunteerDeployed(msg.sender, address(token_distributor)); // @dev Emit event for deployment
        return address(token_distributor); // @dev Return the address of the deployed contract
    }

    /**
     * @dev Deploys a new VolunteerNFT contract
     * @param uri The URI of the NFT
     * @param owner The address of the owner of the VolunteerNFT
     * @param _name The name of the deployed contract
     * @return The address of the newly deployed VolunteerNFT
     */
    function deployVolunteerNFT(
        string memory uri, 
        address owner,
        string memory _name
    ) external returns (address) {
        VolunteerNFT volunteer_nft = new VolunteerNFT(uri, owner, _name);
        deployedVolunteersNFT[msg.sender] = address(volunteer_nft);
        emit VolunteerDeployed(msg.sender, address(volunteer_nft));
        return address(volunteer_nft); // @dev Return the address of the deployed contract
    }

    /**
     * @dev Retrieves the address of the deployed TokenDistributor for a given owner
     * @param owner The address of the owner
     * @return The address of the deployed TokenDistributor
     */
    function getDeployedTokenDistributor(address owner) external view returns (address) {
        return deployedTokenDistributors[owner];
    }

    /**
     * @dev Retrieves the address of the deployed VolunteerNFT for a given owner
     * @param owner The address of the owner
     * @return The address of the deployed VolunteerNFT
     */
    function getDeployedVolunteerNFT(address owner) external view returns (address) {
        return deployedVolunteersNFT[owner];
    }
}
