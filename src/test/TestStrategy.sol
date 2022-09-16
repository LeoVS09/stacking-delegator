/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../IBorrower.sol";
import "../ILender.sol";

contract TestStrategy is IBorrower {

    ILender public _lender;
    IERC20 public assets;
    uint256 public loss;

    constructor(
        address wantTokenAddress
    ) {
        assets = IERC20(wantTokenAddress);
    }

    /// Contract of token which this strategy want to borrow and increase
    function want() external view override returns (address) {
        return address(assets);
    }
    
    function lender() external view override returns (address) {
        return address(_lender);
    }

    function setLender(address lender) external {
        _lender = ILender(lender);
    }

    function setLoss(uint256 loss) external {
        loss = loss;
    }

    function borrow(uint256 amount) external {
        _lender.borrow(amount);
    }

    /// Estimated total assets which currently hold in strategy and in stake
    function totalAssets() public view override returns (uint256) {
        return assets.balanceOf(address(this));
    }

    function withdraw(uint256 amount) external override returns (uint256) {
        require(amount <= totalAssets(), "Not have enough money to withdraw");

        assets.transfer(msg.sender, amount - loss);

        return loss;
    }
}