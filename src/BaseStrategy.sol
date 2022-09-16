/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./IBorrower.sol";
import "./ILender.sol";
import "./SimpleVault.sol";

abstract contract BaseStrategy is Initializable, IBorrower, OwnableUpgradeable, SimpleVault {

    ILender public _lender;

    string public name;
    
    /// name - name of the token
    /// wantAddress - address of ERC20 token contract which will be stored in fund
    /// vaultAddress - address of token where possible stake token
    function __BaseStrategy__init(
        string memory _name,
        address wantAddress,
        address lenderAddress
    ) initializer public {
        __Ownable_init();
        __SimpleVault_init(wantAddress);
        name = _name;
        _lender = ILender(lenderAddress);
    }

    modifier onlyLender() {
        require(address(_lender) == msg.sender, "Strategy: caller is not a vault");
        _;
    }

    /// Contract of token which this strategy want to borrow and increase
    function want() external view override returns (address) {
        return address(assets);
    }
    
    function lender() external view override returns (address) {
        return address(_lender);
    }

    function setLender(address lender) external onlyOwner {
        _lender = ILender(lender);
    }
}