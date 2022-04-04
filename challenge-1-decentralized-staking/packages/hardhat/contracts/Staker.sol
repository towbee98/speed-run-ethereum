// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  bool openForWithdraw=false;


  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted(){
    require(!exampleExternalContract.completed(),"It is completed ");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  mapping (address=>uint256) public balances;
  uint256 public constant threshold= 1 ether;
 event Stake(address indexed _addr,uint256 indexed amount);
  uint256 public deadline = block.timestamp + 72 hours;


  function stake()payable public returns(uint256){
    // require(balances[msg.sender]<=threshold);
        balances[msg.sender]+=msg.value;
        emit Stake(msg.sender,msg.value);
        return balances[msg.sender];
  }


  // After some `deadline` allow anyone to call an `execute()`   
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
function execute()public notCompleted {
  require(deadline<block.timestamp,"Deadline has not expired");

   if(address(this).balance>= threshold){
     exampleExternalContract.complete{value:address(this).balance}();
   }
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  else{
   openForWithdraw=true;
  }
}

  

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted returns (bool){
    require(openForWithdraw==true,"You are not allowed to withdraw");
     //bool success= payable(address(msg.sender)).send(balances[msg.sender]);
      //return true;

    // get the amount of Ether stored in this contract
        uint amount = balances[msg.sender];
        // send all Ether to owner 
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = payable(address(msg.sender)).call{value: amount}("");
        require(success, "Failed to send Ether");
       return success;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft()public view returns(uint256) { 
    if(block.timestamp>=deadline){
       return 0;       
    }
    return deadline- block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive()external payable {
    stake();
  }


}
