// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Random{
 
    uint8 private nonce = 0;
    
    function random() public returns(uint8){
        nonce = uint8(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce)))%100);
        return nonce;
    }
    
}