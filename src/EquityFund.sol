// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./SimpleVault.sol";

/// Implementation of abstract equity fund
/// It allow users to deposit tokens in exchange of shares of this fund
/// And allow exchange shares to widthdraw tokens stored in fund
contract EquityFund is Initializable, SimpleVault, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    /// 100% or 10k basis points for loss
    uint256 constant MAX_BASIS_POINTS = 10_000;

    /// Fired when new amount of tokens deposited and shares a issued for holder
    event Deposit(uint256 amount, uint256 shares, address holder);
    /// Fired when assets for a given shares a withdrawn
    event Withdraw(address holder, uint256 maxShares, uint256 maxLoss, uint256 shares, uint256 amount, uint256 totalShares);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param storageTokenAddress - address of ERC20 token contract which will be stored in fund
    /// @param name - name of the token
    /// @param symbol - token symbol
    function __EquityFund_init(string memory name, string memory symbol, address storageTokenAddress) initializer public {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Ownable_init();
        __SimpleVault_init(storageTokenAddress);
    }

    /// Add deposit to fund storage and issues shares for a recepient
    /// Mint shares based on expected value under control at the moment
    /// Not collect real assets from borrowers, as it allow manipulate issue rate
    /// Will transfer `amount` of tokens from `message sender` and issue shares to him
    function deposit(uint256 amount) external nonReentrant returns (uint256) {
        // Do not allow specify sender and holder, 
        //  as it allow someone use not his tokens for issue shares to someone else
        require(amount > 0, "For deposit amount must be non-zero");

        // Issue new shares (needs to be done before taking deposit to be accurate)
        uint256 shares = _issueShares(amount, msg.sender);

        // Transfer tokens from sender to this contract
        _receiveAssetsFrom(msg.sender, amount);

        emit Deposit(amount, shares, msg.sender);
        return shares;
    }

    /// Withdraws the calling account's tokens from this Vault, redeeming
    ///  amount `maxShares` for an appropriate amount of tokens.
    ///  As holder address will be used message sender
    /// @param maxShares - How many shares to try redeem for tokens, if will be not possible redeem all, then will be redeemed only available partially
    /// @param maxLoss - The maximum acceptable loss to sustain on withdrawal.
    ///  Up to that amount of shares can be burnt to cover losses on withdrawal.
    ///  Represented in uint256, where 1 equal 0.01%.
    function withdraw(uint256 maxShares, uint256 maxLoss) external nonReentrant returns (uint256) {
        // Do not allow specify holder address. If method called by someone other, 
        //  he can burn shares someone another by calling this method
        require(maxShares > 0, "Shares amount must be non-zero");
        require(maxLoss <= MAX_BASIS_POINTS, "maxLoss is bigger 100%");
        require(maxShares <= balanceOf(msg.sender), "More shares specified, sender not have enough");

        // Reddem shares for some amount of tokens
        (uint256 shares, uint256 amount) = _redeemShares(maxShares, maxLoss);

        // Send remaining balance to msg.sender (minus fee)
        _transferAssets(msg.sender, amount);

        emit Withdraw(msg.sender, maxShares, maxLoss, shares, amount, totalSupply());
        return amount;
    }

    /// Issues `amount` fund shares to `holder`.
    /// Shares must be issued prior to taking on new collateral, or
    /// calculation will be wrong. This means that only *trusted* tokens
    /// (with no capability for exploitative behavior) can be used.
    function _issueShares(uint256 amount, address holder) internal virtual returns (uint256) {
        uint256 shares = _estimateShares(amount);
        _mint(holder, shares);
        return shares;
    }

    /// Redeem up to `maxShares` for assets, and return `redeemd shares, assets ammount`.
    /// Allow `maxLoss`
    function _redeemShares(uint256 maxShares, uint256 maxLoss) internal virtual returns (uint256, uint256) {
        // Calculate how much tokens must be withdraw based on current assets of the fund
        uint256 value = _estimateShareValue(maxShares);
        // Burn shares (full value of what is being withdrawn)
        _burn(msg.sender, maxShares);
        return (maxShares, value);
    }

    /// Estimate how much shares should be issued if given amount will be added to fund
    function _estimateShares(uint256 amount) internal virtual view returns (uint256) {
        require(amount > 0, "For issue shares amount must be non-zero");
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            // No existing shares, so mint 1:1
            return amount;
        }

        // Mint amount of shares based on what the fund is managing overall
        // if sqrt(totalSupply()) > 1e39, this could potentially revert
        // TODO: use safe math
        // TODO: use rounding calculation
        uint256 shares = amount * totalShares / _expectedAssets();
        require(shares > 0, "Incorrect calcualtion of shares during issing"); // rounding calcualtion must fix it

        return shares;
    }

    /// Estimate how much tokens must be withdraw based on current assets of the fund 
    function _estimateShareValue(uint256 shares) internal virtual view returns (uint256) {
        require(shares > 0, "For estimate value shares amount must be non-zero");
        
        uint256 totalShares = totalSupply();
        require(shares <= totalShares, "Cannot calcualte value for not existing shares");
        
        // Determines the current value of `shares`.
        // if sqrt(_expectedAssets()) >>> 1e39, this could potentially revert
        // TODO: use safe math
        // TODO: use rounding calculation
        uint256 expectedAssets = _expectedAssets();
        uint256 value = shares * expectedAssets / totalShares;
        require(shares > 0, "Incorrect calcualtion of share's value"); // rounding calcualtion must fix it

        return value;
    }

    /// Calculate how much assets currently have fund 
    function _expectedAssets() internal virtual view returns (uint256) {
        // Need override with calcualtions based on farming method
        return _availableAssets();
    }
}
