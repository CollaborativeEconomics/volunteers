// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import {IVolunteer} from "./interface/IVolunteer.sol";

/**
 * @title TokenDistributor
 * @author Lawal Abubakar Babatunde
 * @dev A contract for distributing tokens to whitelisted addresses holding NFTs
 */
contract TokenDistributor is Owned, IVolunteer {
    /// @notice The list of acceptable tokens
    address public token;
    /// @dev List of addresses registered for token distribution
    address[] public registeredAddresses;
    /// @notice The NFT contract to check ownership
    ERC1155 public nftContract;
    /// @dev Mapping to check if a wallet is whitelisted
    mapping(address => bool) public whitelisted;
    /// @dev Base fee per unit of activities defined by the organization
    uint256 public baseFee;
    /// @dev Token ID that qualifies volunteer for payment.
    uint8 constant NFT_TOKEN_ID_TWO = 2;

    /// @dev Event emitted when tokens are distributed
    event TokensDistributed(address indexed recipient, uint256 amount);

    /**
     * @dev Constructor to initialize the contract with tokens, NFT contract, and owner
     */
    constructor(address _token, address _owner, ERC1155 _nftContract, uint256 _baseFee)
        Owned(_owner)
    {
        token = _token;
        nftContract = _nftContract; // @dev Set the NFT contract
        baseFee = _baseFee;
    }

    function distributeTokensByUnit(address[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");

        // Cache the length of registeredAddresses
        uint256 recipientsLength = recipients.length;

        // Now distribute ERC20 tokens
        // for (uint256 j = 0; j < tokens.length; j++) {
        IERC20 tokenContract = IERC20(token);
        uint256 tokenBalance = tokenContract.balanceOf(address(this)); // @dev Get the token balance of the contract

        if (tokenBalance > 0) {
            for (uint256 i = 0; i < recipientsLength; i++) {
                address currentAddress = recipients[i];
                uint256 currentAddressNFTBalance = nftContract.balanceOf(currentAddress, NFT_TOKEN_ID_TWO);
                if (currentAddressNFTBalance > 0) {
                    uint256 currentAddressShare = currentAddressNFTBalance * baseFee;
                    tokenContract.transfer(currentAddress, currentAddressShare); // @dev Send tokens
                    emit TokensDistributed(currentAddress, currentAddressShare); // @dev Emit event for distribution
                }
            }
        }
    }

    /**
    * @dev Withdraws the remaining tokens from the contract after the campaign has ended
    * This function is only callable by the owner
    */
    function withdrawToken() external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        uint256 tokenBalance = tokenContract.balanceOf(address(this)); // @dev Get the token balance of the contract
        tokenContract.transfer(owner, tokenBalance); // @dev Send the remaining tokens to the owner
    }

    /**
     * @dev Whitelists multiple addresses for token distribution
     * @param _addresses The list of addresses to be whitelisted
     */
    function whitelistAddresses(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            // @dev Check if the address is not already whitelisted
            if (!whitelisted[_addresses[i]]) {
                whitelisted[_addresses[i]] = true; // @dev Mark each address as whitelisted
                registeredAddresses.push(_addresses[i]); // @dev Add the address to registered addresses
            }
        }
    }

    /**
     * @dev Removes an address from the whitelist
     * @param user The address to be removed from the whitelist
     */
    function removeFromWhitelist(address user) external onlyOwner {
        whitelisted[user] = false; // @dev Mark the address as not whitelisted
    }

    /**
     * @dev Adds a new token address to the list of acceptable tokens
     * @param tokenAddress The address of the token to be added
     */
    function changeTokenAddress(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address"); // @dev Ensure the token address is valid
        token = tokenAddress; // @dev Add the token address to the list
    }

    /**
     * @dev Updates the whitelist and registers a new user
     * @param user The address to be added to the whitelist
     */
    function updateWhitelist(address user) external onlyOwner {
        whitelisted[user] = true; // @dev Mark the address as whitelisted
        registeredAddresses.push(user); // @dev Add the address to registered addresses
    }

    /**
     * @dev Updates the base fee
     * @param _baseFee The new base fee
     */
    function updateBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee; // @dev Update the base fee
    }

    /**
     * @dev Returns the current donation token address
     * @return _token The current donation token address
     */
    function getToken() external view returns (address _token) {
        _token = token; // @dev Return the list of tokens
        return _token;
    }

    /**
     * @dev Returns the list of whitelisted addresses
     * @return whitelist The list of whitelisted addresses
     */
    function getWhitelistedAddresses() external view returns (address[] memory whitelist) {
        whitelist = registeredAddresses; // @dev Return the list of registered addresses
    }

    /**
     *
     * @dev Returns the current base fee
     * @return _baseFee The current base fee
     */
    function getBaseFee() external view returns (uint256 _baseFee) {
        _baseFee = baseFee; // @dev Return the base fee
    }

    /**
     * @dev Checks if a user is whitelisted
     * @param user The address to check
     * @return status True if the user is whitelisted, false otherwise
     */
    function isWhitelisted(address user) external view returns (bool status) {
        status = whitelisted[user]; // @dev Return the whitelist status of the user
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {} // @dev Allow the contract to receive ETH
}
