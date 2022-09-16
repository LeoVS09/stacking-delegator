/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface ILender {

    /**
     * View how much the Lender allow to increase this Borrower's borrow limit.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * Allow borrow some money from the Lender.
     */
    function borrow(uint256 amount) external;

}