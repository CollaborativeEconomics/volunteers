// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Owned} from "lib/solmate/src/auth/Owned.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ERC1155TokenGatedDistributor
 * @dev ERC1155 token that gates reward distribution based on token ownership
 */
contract ERC1155TokenGatedDistributor is ERC1155, Owned {
    using SafeERC20 for IERC20;

    // Token IDs
    uint256 public constant PROOF_OF_ATTENDANCE = 1;
    uint256 public constant PROOF_OF_ENGAGEMENT = 2;

    // Reward token configuration
    address public rewardToken;
    uint256 public baseFee;

    // Holder tracking
    mapping(address => bool) private isHolder;
    address[] private holders;

    // Events
    event TokensDistributed(address indexed recipient, uint256 amount);
    event RewardTokenChanged(address indexed newToken);
    event BaseFeeUpdated(uint256 newBaseFee);
    event HolderAdded(address indexed holder);
    event HolderRemoved(address indexed holder);

    constructor(
        string memory uri,
        address owner,
        address _rewardToken,
        uint256 _baseFee
    ) ERC1155(uri) Owned(owner) {
        require(_rewardToken != address(0), "Invalid token address");
        rewardToken = _rewardToken;
        baseFee = _baseFee;
    }

    function _updateHolder(address from, address to, uint256 id) internal {
        if (id != PROOF_OF_ENGAGEMENT) return;

        if (to != address(0) && balanceOf(to, id) > 0 && !isHolder[to]) {
            isHolder[to] = true;
            holders.push(to);
            emit HolderAdded(to);
        }

        if (from != address(0) && balanceOf(from, id) == 0 && isHolder[from]) {
            isHolder[from] = false;
            _removeHolder(from);
            emit HolderRemoved(from);
        }
    }

    function _removeHolder(address holder) internal {
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == holder) {
                holders[i] = holders[holders.length - 1]; // Swap with last
                holders.pop(); // Remove last element
                break;
            }
        }
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._update(from, to, ids, amounts);
        for (uint256 i = 0; i < ids.length; i++) {
            _updateHolder(from, to, ids[i]);
        }
    }

    function mint(address to, uint256 tokenId, uint256 amount) external onlyOwner {
        require(tokenId == PROOF_OF_ATTENDANCE || tokenId == PROOF_OF_ENGAGEMENT, "Invalid token ID");
        _mint(to, tokenId, amount, "");
    }

    function burn(address from, uint256 tokenId, uint256 amount) external onlyOwner {
        _burn(from, tokenId, amount);
    }

    function getEligibleHolders() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            if (balanceOf(holders[i], PROOF_OF_ENGAGEMENT) > 0) {
                count++;
            }
        }

        address[] memory validHolders = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            if (balanceOf(holders[i], PROOF_OF_ENGAGEMENT) > 0) {
                validHolders[index] = holders[i];
                index++;
            }
        }

        return validHolders;
    }

    function distributeTokens() external onlyOwner {
        IERC20 tokenContract = IERC20(rewardToken);
        uint256 contractBalance = tokenContract.balanceOf(address(this));
        require(contractBalance > 0, "No tokens available for distribution");

        address[] memory eligibleHolders = getEligibleHolders();
        require(eligibleHolders.length > 0, "No eligible recipients");

        uint256 totalRequired = eligibleHolders.length * baseFee;
        require(contractBalance >= totalRequired, "Insufficient funds");

        for (uint256 i = 0; i < eligibleHolders.length; i++) {
            tokenContract.safeTransfer(eligibleHolders[i], baseFee);
            emit TokensDistributed(eligibleHolders[i], baseFee);
        }
    }

    function setRewardToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Invalid token address");
        rewardToken = newToken;
        emit RewardTokenChanged(newToken);
    }

    function setBaseFee(uint256 newBaseFee) external onlyOwner {
        baseFee = newBaseFee;
        emit BaseFeeUpdated(newBaseFee);
    }

    function withdrawRewardTokens() external onlyOwner {
        IERC20 tokenContract = IERC20(rewardToken);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(owner, balance);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://", Strings.toString(id)));
    }

    receive() external payable {}
}