// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;
  bool private executed = false;

  event Stake(address, uint256);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(),  "Contract is not completed yet!");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted {
    require(!executed,  "Contract was executed!");
    uint256 stakeBalance = address(this).balance;
    if (block.timestamp > deadline ) {
      if (stakeBalance >= threshold) {
        exampleExternalContract.complete{value: stakeBalance}();
      } else {
        openForWithdraw = true;
      }
      executed = true;
    }
  }

  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }

    return deadline - block.timestamp;
  }

  function withdraw() public {
    if (!openForWithdraw ) {
      if (executed) {
        revert("Campaign was executed! Cannot withdraw anymore!");
      } else {
        revert("Campaign has not ended yet!");
      }
    }

    uint256 stakedBalance = balances[msg.sender];
    require(stakedBalance > 0, "You have not staked yet! No ETH for withdrawing!");

    (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
    require(sent, "Failed to withdraw!");
    balances[msg.sender] = 0;
  }

  receive() external payable {
    stake();
  }
}
