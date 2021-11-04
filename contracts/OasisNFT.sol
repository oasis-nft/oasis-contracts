// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OasisNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private constant OPTION_HASH = "0x4b4c2a4a9ea2fb5b16063454369ead4d88697648fbbe4e30f5224e71c65cd136";
    string private _uri;
    uint256 private _maxSupply;

    constructor(string memory name_, string memory symbol_, string memory uri_, uint256 maxSupply_) ERC721(name_, symbol_) {
        _uri = uri_;
        _maxSupply = maxSupply_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual {
        _uri = newuri;
    }

    function getOptionHash() public pure returns (string memory) {
        return OPTION_HASH;
    }

    function safeMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() <= _maxSupply - 1, "Max amount minted");

        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function batchMint(address to, uint256 number) public onlyOwner {
        for(uint i=0; i < number; i++) {
            safeMint(to);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
