// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {IVolunteer} from "./interface/IVolunteer.sol";

contract TokenDistributor is Owned, IVolunteer {
    ERC20 public token;
    ERC721 public nftContract; // The NFT contract to check ownership
    mapping(address => bool) public whitelisted;
    address[] public registeredAddresses;
    address[] public tokenAddresses;

    event TokensDistributed(address indexed recipient, uint256 amount);

    constructor(ERC20 _token, ERC721 _nftContract, address _contract_owner) Owned(_contract_owner) {
        token = _token;
        nftContract = _nftContract;
    }

    function updateToken(ERC20 _token) external onlyOwner {
        token = _token;
    }

    function whitelistAddresses(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
        registeredAddresses = _addresses;
    }

    function removeFromWhitelist(address user) external onlyOwner {
        whitelisted[user] = false;
    }

    // Function to add token addresses
    function addTokenAddress(address tokenAddress) external {
        require(tokenAddress != address(0), "Invalid token address");
        tokenAddresses.push(tokenAddress);
    }

    function distributeTokens() external onlyOwner {
        address[] memory recipients = registeredAddresses;
        require(recipients.length > 0, "No recipients provided");

        uint256 totalTokenBalance = address(this).balance; // Start with ETH balance
        uint256 whitelistCount = 0;

        // Count whitelisted addresses
        for (uint256 i = 0; i < recipients.length; i++) {
            if (whitelisted[recipients[i]]) {
                whitelistCount++;
            }
        }

        // Calculate amount per recipient for ETH
        uint256 amountPerRecipient;

        if (totalTokenBalance > 0) {
            amountPerRecipient = totalTokenBalance / whitelistCount;
        }

        // Distribute ETH
        for (uint256 i = 0; i < recipients.length; i++) {
            address currentAddress = recipients[i];
            if (whitelisted[currentAddress]) {
                if (nftContract.balanceOf(currentAddress) > 0) {
                    payable(currentAddress).transfer(amountPerRecipient); // Send ETH
                    emit TokensDistributed(currentAddress, amountPerRecipient);
                }
            }
        }

        // Now distribute ERC20 tokens
        for (uint256 j = 0; j < tokenAddresses.length; j++) {
            IERC20 tokenContract = IERC20(tokenAddresses[j]);
            uint256 tokenBalance = tokenContract.balanceOf(address(this));

            if (tokenBalance > 0) {
                uint256 amountPerTokenRecipient = tokenBalance / whitelistCount;

                for (uint256 i = 0; i < recipients.length; i++) {
                    address currentAddress = recipients[i];
                    if (whitelisted[currentAddress]) {
                        if (nftContract.balanceOf(currentAddress) > 0) {
                            tokenContract.transfer(currentAddress, amountPerTokenRecipient); // Send tokens
                            emit TokensDistributed(currentAddress, amountPerTokenRecipient);
                        }
                    }
                }
            }
        }
    }

    function updateWhitelist(address user) external onlyOwner {
        whitelisted[user] = true;
        registeredAddresses.push(user);
    }

    function getToken() external view returns (address currentToken) {
        currentToken = address(token);
        return currentToken;
    }

    function getWhitelistedAddresses() external view returns (address[] memory whitelist) {
        whitelist = registeredAddresses;
        return whitelist;
    }

    function isWhitelisted(address user) external view returns (bool status) {
        status = whitelisted[user];
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}
}
