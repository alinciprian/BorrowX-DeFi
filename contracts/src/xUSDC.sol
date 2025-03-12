//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Burnable, ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Stable Coin X
/// @author AlinCiprian
/// Collateral: wETH and wBTC
/// Pegged to USD
/// This contract is meant to be an ERC20 stablecoin that can be borrowed from BorrowX contract in exchange for locking an appropriate amount
/// of colateral

contract xUSDC is ERC20Burnable, Ownable {
    error xUSDC__BalanceMustBeMoreThanZero();
    error xUSDC__BurnAmountExceedsBalance();
    error xUSDC__NotZeroAddress();
    error xUSDC__MintAmountIsZero();

    constructor() ERC20("StableCoinX", "SCX") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert xUSDC__BalanceMustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert xUSDC__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert xUSDC__NotZeroAddress();
        }
        if (_amount < 0) {
            revert xUSDC__MintAmountIsZero();
        }

        _mint(_to, _amount);
        return true;
    }
}
