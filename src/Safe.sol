// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Safe {
    receive() external payable {}

    function withdraw(uint password) external returns (uint256) {
        require(password == 42, "Access denied!");


        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        return balance;
    }
}