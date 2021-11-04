// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OasisNFT.sol";

contract TokenTransfer {
  function transferTokens(address erc721TokenAddress, address sendTo, uint256[] memory _ids) public {
    OasisNFT tokenForSale = OasisNFT(erc721TokenAddress);

      // check if all tokens are owned by sender
    for(uint i=0; i < _ids.length; i++) {
      require(tokenForSale.ownerOf(_ids[i]) == msg.sender, "Token not owned by contract");
    }

    // transfer tokens
    for(uint i=0; i < _ids.length; i++) {
      tokenForSale.safeTransferFrom(msg.sender, sendTo, _ids[i]);
    }

  }
}
