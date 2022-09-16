/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./SimpleVault.sol";
import "./IBorrower.sol";
import "./ILender.sol";

/// Implementation of abstract lender contract
/// It allow to borrow tokens from this contract by only one whitelabeled strategy
/// And also have internal method,
/// which can be used in inherited contract to widthdraw tokens from strategy
contract Lender is ILender, Initializable, SimpleVault, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    /// Amount of tokens that all strategies have borrowed.
    uint256 public totalDebt;

    IBorrower public strategy;

    /// Emit when strategy borrow some assets
    event Borrowed(address strategy, uint256 amount, uint256 strategyTotalAssets, uint256 totalDebt);
    /// Emit when assets returned from strategy
    event ReturnFromStrategy(uint256 previusBalance, uint256 targetBalance, uint256 requestedAmount, uint256 loss);

    // function initialize(address strategyAddress, address storageTokenAddress) initializer public {
    //     __Ownable_init();
    //     __SimpleVault_init(storageTokenAddress);
    //     __Lender_init(strategyAddress);
    // }

    function __Lender_init(address strategyAddress) internal {
        setStrategy(strategyAddress);
    }

    modifier onlyStrategy() {
        require(address(strategy) == _msgSender(), "Lender: caller is not a strategy");
        _;
    }

    function setStrategy(address strategyAddress) public onlyOwner {
        strategy = IBorrower(strategyAddress);

        // TODO: check also lender is correct when adding strategy
        require(strategy.want() == address(assets), "Strategy do not want vault assets");
    }

    /// Strategy can requests some credit which then must return
    function borrow(uint256 amount) public override onlyStrategy nonReentrant {
        require(amount > 0, "Borrowing amount must be positive");
        require(amount <= _availableAssets(), "Requested more then available for a borrowing");

        // TODO: use safe math
        totalDebt += amount;
      
        _transferAssets(msg.sender, amount);

        emit Borrowed(msg.sender, amount, IBorrower(msg.sender).totalAssets(), totalDebt);
    }

    /// Estimate how much strategy can borrow from this Lender.
    function creditAvailable() external override onlyStrategy view returns (uint256) {
        // TODO: When will be borrow ratio need calculate based on it
        return _availableAssets();
    } 

    /// Hook which must return assets to lender if it possible
    /// @param targetBalance - balance which fund must have at the end of hook executuin
    /// @return totalLoss - loss of all performed actions
    function _returnAssets(uint256 targetBalance) internal virtual returns (uint256) {
        // Calcualte amount of assets which should be widthdraw
        // TODO: use safe math
        uint256 currentAssets = _availableAssets();
        uint256 amountNeed = targetBalance - currentAssets;

        if (totalDebt < amountNeed) {
            totalDebt = 0;
        } else {
            totalDebt -= amountNeed;
        }

        uint256 loss = strategy.withdraw(amountNeed);
        emit ReturnFromStrategy(currentAssets, targetBalance, amountNeed, loss);

        return loss;
    }

    /// Returns the total quantity of all assets under control of this
    /// fund, whether they're loaned out to a strategy, or currently held in
    /// the fund.
    function totalAssets() public view returns (uint256) {
        return _availableAssets() + strategy.totalAssets();
    }




}