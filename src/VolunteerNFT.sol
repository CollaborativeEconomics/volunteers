// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract VolunteerNFT is ERC721, Owned {
    constructor(string memory name, string memory symbol, address owner) ERC721(name, symbol) Owned(owner) {}

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://", Strings.toString(id)));
    }
}
