// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * SimpleVault for store underlaing "assets", 
 * where assets represented as ERC20 token. Allow borrow assets for another accounts.
 */
contract SimpleVault is Initializable {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// Contract of token which will be stored in this vault
    IERC20Upgradeable public assets;
    
    /**
     * @dev Sets the values for {assets}.
     *
     * Init ERC20 based contract with given address
     */
    function __SimpleVault_init(address storageTokenAddress) initializer internal {
        assets = IERC20Upgradeable(storageTokenAddress);
    }

    /// Transfer assets from given address to this contract
    function _receiveAssetsFrom(address from, uint256 value) internal {
        _transferAssetsFrom(from, address(this), value);
    }

    /// Safely transfer assets token from given address to sender
    function _transferAssetsFrom(address from, address to, uint256 value) internal {
        assets.safeTransferFrom(from, to, value);
    }

    /// Safely transfer assets token to sender
    function _transferAssets(address to, uint256 value) internal {
        assets.safeTransfer(to, value);
    }

    function _increaseAssetsAllowance(address spender, uint256 value) internal {
        assets.safeIncreaseAllowance(spender, value);
    }

    function _decreaseAssetsAllowance(address spender, uint256 value) internal {
        assets.safeDecreaseAllowance(spender, value);
    }


    /// Assets which are directly available for fund
    function _availableAssets() internal view returns (uint256) {
        return assets.balanceOf(address(this));
    }
}
