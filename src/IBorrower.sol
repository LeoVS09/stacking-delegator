/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// Interface of Borrowe which need implement to allow communicate with Lender
interface IBorrower {
    /// Token address which this borrower want to borrow
    function want() external view returns (address);
    /// Lender address from which this borrower want to request token.
    function lender() external view returns (address);
    /// Try to widthdraw given amount and return loss
    function withdraw(uint256 amount) external returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function totalAssets() external view returns (uint256);
}