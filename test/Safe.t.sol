// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import "forge-std/Test.sol";
import {Safe} from "../src/Safe.sol";

contract SafeTest is Test {
    Safe safe;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    function setUp() public {
        safe = new Safe();

        // By some reason deployed contract have money by default
        if (address(safe).balance > 0) {
            safe.withdraw(42);
        }
    }

    function testWithdraw(uint96 amount) public {
        payable(address(safe)).transfer(amount);

        uint256 preBalance = address(this).balance;
        safe.withdraw(42);

        uint256 postBalance = address(this).balance;
        assertEq(preBalance + amount, postBalance);
    }

    function testFail_withdraw_wrong_pass() public {
        payable(address(safe)).transfer(1 ether);

        uint preBalance = address(this).balance;

        safe.withdraw(1);

        uint postBalance = address(this).balance;

        assertEq(preBalance + 1 ether, postBalance);
    }

    // Not working in 0.49.0 version of dapptools https://github.com/dapphub/dapptools/issues/934
    // function proveFail_withdraw(uint guess) public {
    //     payable(address(dapptutorial)).transfer(1 ether);

    //     uint preBalance = address(this).balance;

    //     dapptutorial.withdraw(guess);

    //     uint postBalance = address(this).balance;
        
    //     assertEq(preBalance + 1 ether, postBalance);
    // }


}