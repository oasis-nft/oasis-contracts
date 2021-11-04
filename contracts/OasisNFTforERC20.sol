// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OasisNFT.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract OasisNFTforErc20 is ERC721Holder, Ownable {
  ERC20 public acceptedERC20Token;
  OasisNFT public nftForSale;

  // token price for ETH
  uint256 public tokensPerNFT = 100;
  uint256 public maxPerTx = 25;

  bool public saleActive = false;
  uint256 public tokensSold = 0;

  event StartSaleEvent();
  event EndSaleEvent();
  event WithdrawERC20Event(uint256 amount);
  event WithdrawERC721Event(uint256 amount);
  event SetPriceEvent(uint256 amount);
  event SetMaxEvent(uint256 amount);

  constructor(address erc20TokenAddress, address erc721TokenAddress, uint256 price, uint256 max) {
    acceptedERC20Token = ERC20(erc20TokenAddress);
    nftForSale = OasisNFT(erc721TokenAddress);
    tokensPerNFT = price;
    maxPerTx = max;
  }

  function startSale() external onlyOwner {
    saleActive = true;
    emit StartSaleEvent();
  }
  function endSale() external onlyOwner {
    saleActive = false;
    emit EndSaleEvent();
  }

  /**
  * @notice Set erc20 price per token.
  */
  function setPrice(uint256 newPrice) public onlyOwner {
    require(newPrice > 0, "Price must be bigger than 0");
    tokensPerNFT = newPrice;
    emit SetPriceEvent(newPrice);
  }

  /**
  * @notice Set maximum ammount per swap.
  */
  function setMax(uint256 newMax) public onlyOwner {
    require(newMax > 0, "Max must be bigger than 0");
    maxPerTx = newMax;
    emit SetMaxEvent(newMax);
  }

  /**
  * @notice Buy tokens. Caller must have high enough ERC20 tokens approved.
  */
  function buyTokens(uint256 tokenAmountToBuy) external {
    // Sale must be active
    require(saleActive, "Sale not active");

    // Check that the requested amount of tokens to sell is more than 0
    require(tokenAmountToBuy > 0, "Buy more than zero");

    // Check if we stay below max per tx
    require(tokenAmountToBuy <= maxPerTx, "Cant buy more than max");

    uint256 userBalance = acceptedERC20Token.allowance(msg.sender, address(this));
    // Calculate totalprice for sale
    uint256 totalPrice = tokenAmountToBuy * tokensPerNFT;

    // Check that the user's token allowance is high enough to do the swap
    require(totalPrice <= userBalance, "Your ERC20 balance is too low");

    //check if we have enough tokens to sell
    uint256 balanceForSale = nftForSale.balanceOf(address(this));
    require(balanceForSale >= tokenAmountToBuy, "Not enough tokens to sell");

    // select tokenIds to transfer
    uint256[] memory tokenIdsToTransfer = new uint256[](tokenAmountToBuy);
    for(uint i=0; i < tokenAmountToBuy; i++) {
      tokenIdsToTransfer[i] = nftForSale.tokenOfOwnerByIndex(address(this), i);
    }

    // check if the selectedIds match the length requested
    require(tokenIdsToTransfer.length == tokenAmountToBuy, "Error selecting tokenIDs to transfer");

    // transfer ERC20 tokens
    (bool received) = acceptedERC20Token.transferFrom(msg.sender, address(this), totalPrice);
    require(received, "Failed to transfer ERC20 tokens from user to vendor");

    // send ERC 721 tokens
    for(uint i=0; i < tokenIdsToTransfer.length; i++) {
      // Add to tokens sold and transfer
      nftForSale.safeTransferFrom(address(this), msg.sender, tokenIdsToTransfer[i]);
      tokensSold += 1;
    }
  }

  /**
  * @notice Allow the owner of the contract to Withdraw ERC20
  */
  function withdrawERC20() external onlyOwner {
    uint256 ownerBalance = acceptedERC20Token.balanceOf(address(this));

    require(ownerBalance > 0, "Owner has no balance to Withdraw");

    (bool sent) = acceptedERC20Token.transfer(msg.sender, ownerBalance);
    require(sent, "Failed to send ERC20 balance back to the owner");

    emit WithdrawERC20Event(ownerBalance);
  }

  /**
  * @notice Allow the owner of the contract to Withdraw specific ERC721
  */
  function withdrawERC721(uint256[] memory _ids) external onlyOwner {
    uint256 ownerBalance = nftForSale.balanceOf(address(this));
    require(ownerBalance > 0, "Owner has no balance to Withdraw");

    // check if all tokens are owned by this contract
    for(uint i=0; i < _ids.length; i++) {
      require(nftForSale.ownerOf(_ids[i]) == address(this), "Token not owned by contract");
    }

    // transfer tokens
    for(uint i=0; i < _ids.length; i++) {
      nftForSale.safeTransferFrom(address(this), msg.sender, _ids[i]);
    }

    emit WithdrawERC721Event(_ids.length);
  }
}
