// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Ownable} from "solmate/auth/Owned.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TokenDistributor is Ownable {
    ERC20 public token;
    IERC721 public nftContract; // The NFT contract to check ownership
    mapping(address => bool) public whitelisted;

    event TokensDistributed(address indexed recipient, uint256 amount);

    constructor(ERC20 _token, IERC721 _nftContract) {
        token = _token;
        nftContract = _nftContract;
    }

    function whitelistAddress(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = false;
    }

    function distributeTokens(address[] calldata recipients, uint256 totalAmount) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient token balance in contract");

        uint256 amountPerRecipient = totalAmount / recipients.length; // Calculate amount per recipient

        for (uint256 i = 0; i < recipients.length; i++) {
            require(whitelisted[recipients[i]], "Address not whitelisted");
            require(nftContract.balanceOf(recipients[i]) > 0, "Address does not hold the required NFT");
            token.transfer(recipients[i], amountPerRecipient);
            emit TokensDistributed(recipients[i], amountPerRecipient);
        }
    }
}