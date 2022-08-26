pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfETH, uint256 amountOfTokens);

  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  function buyTokens() public payable {
    uint256 amountOfETH = msg.value; // msg.value is wei unit
    uint256 amountOfTokens = amountOfETH * tokensPerEth;
    bool success = yourToken.transfer(msg.sender, amountOfTokens);
    require(success, "Transfer token was failed!");

    emit BuyTokens(msg.sender, amountOfETH, amountOfTokens);
  }

  function withdraw() public onlyOwner {
    address ownerAddress = owner();
    uint256 amount = address(this).balance;
    (bool success, ) = ownerAddress.call{value: amount}("");
    require(success, "Failed to send ETH to owner account!");
  }

  function sellTokens(uint256 _amount) public {
    // TODO: check if we need to use the transaction to revert the action, in case the ETH failed to send back to user
    bool success = yourToken.transferFrom(msg.sender, address(this), _amount);
    require(success, "Failed to transfer the token to vendor!");

    uint256 amountOfETH = _amount / tokensPerEth;
    (success, ) = msg.sender.call{value: amountOfETH}("");
    require(success, "Failed to send ETH back to user!");

    emit SellTokens(msg.sender, amountOfETH, _amount);
  }

}
