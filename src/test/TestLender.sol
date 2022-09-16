/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../IBorrower.sol";

/// Lender which simplifies testing of strategies
contract TestLender  {

    function withdraw(address strategy, uint256 amount) external returns (uint256) {
        return IBorrower(strategy).withdraw(amount);
    }



}