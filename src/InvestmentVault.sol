/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EquityFund.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Lender.sol";

/// Simple investment vault, which allow store tokens in vault
/// Tokens can be borrowed by strategy and returned with percents
/// And vault allow widthdraw tokens in proportion of shares which user have
contract InvestmentVault is Initializable, EquityFund, Lender {

    uint256 constant DEGRADATION_COEFFICIENT = 10 ** 18;
    
    /// name - name of the token
    /// symbol - token symbol
    /// storageTokenAddress - address of ERC20 token contract which will be stored in fund
    /// strategyAddress - address of strategy which will stake tokens
    function initialize(
        string memory name, 
        string memory symbol, 
        address storageTokenAddress, 
        address strategyAddress
    ) initializer public {
        __EquityFund_init(name, symbol, storageTokenAddress);
        __Lender_init(strategyAddress);
    }

    /// Redeem up to `maxShares` for assets, and return `redeemd shares, assets ammount`.
    /// Allow `maxLoss`
    function _redeemShares(uint256 maxShares, uint256 maxLoss) internal override returns (uint256, uint256) {
        uint256 shares = maxShares; // May reduce this number below

        // Calculate how much tokens must be withdraw based on current assets of the fund
        uint256 value = _estimateShareValue(maxShares);
        
        if (value > _availableAssets()) {
            // try return assets under control of the fund
            uint256 totalLoss = _returnAssets(value);

            uint256 fundBalance = _availableAssets();
            if (value > fundBalance) {
                // We have withdrawn everything possible out
                // but we still don't have enough to fully pay them back, so adjust
                // to the total amount we've freed up through forced withdrawals
                value = fundBalance;
                // Burn shares that corresponds to what Vault has on-hand,
                // including the losses that were incurred above during withdrawals
                // TODO: use safe math
                shares = _estimateShares(value + totalLoss);

                // Check current shares must be lower than maxShare.
                // This implies that large withdrawals within certain parameter ranges might fail.
                require(shares <= maxShares, "Shares which will be burn with losses is bigger than given maxShares");
            }

            // This loss protection is put in place to revert if losses from
            // withdrawing are more than what is considered acceptable
            // TODO: use safe math
            // TODO: Maybe use rounding calculation
            require(totalLoss <= (value + totalLoss) * maxLoss / MAX_BASIS_POINTS, "Total loss bigger than acceptable maxLoss");
        }

        // Burn shares (full value of what is being withdrawn)
        _burn(msg.sender, shares);

        return (shares, value);
    }

    /// Calculate how much assets currently have fund 
    /// Expectation based on real assets minus probably lost assets
    function _expectedAssets() internal override view returns (uint256) {
        return totalAssets() - _probablyLostAssets();
    }

    /// Assets can be lost because exists time difference between 
    /// moment when assets was borrowed 
    /// and moment when current assets of borrowers was updated. 
    function _probablyLostAssets() internal view returns (uint256) {
        // TODO: Currently Lender contract directly request current assets in strategy
        //  Need make reports of assets asynchronously and 
        //  calculate probably lost assets between reports
        //  Maybe need move this calcualtions to strategy
        return 0;
    }

}
