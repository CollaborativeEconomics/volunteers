// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {VolunteerNFT} from "src/VolunteerNFT.sol";

contract MockERC1155 is VolunteerNFT {
    constructor(string memory uri, address owner) VolunteerNFT(uri, owner, "Mock NFT") {}

    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external {
        _mint(to, tokenId, amount, data);
    }

    function burn(address account, uint256 tokenId, uint256 amount) external {
        _burn(account, tokenId, amount);
    }
}
