//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {xUSDC} from "./xUSDC.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title BorrowX
/// @author AlinCiprian
/// @notice This contract allows users to borrow xUSDC against collateral(wETH); Loan-to-Value will be 50%, meaning that
/// users cand borrow half the value that they lock in the contract. Liquidation threshold will be 75% and it is the point where
/// a position is listed for liquidation. In order to incentivize other users to liquidate the position, the liquidator will receive
/// 10% discount on the collateral.
// xUSDC is backed all the time by an equivalent amount in wETH in order to mantain 1:1 USD ratio.

contract BorrowX is ReentrancyGuard {
    //////////////////////
    ///Errors
    //////////////////////
    error BorrowX__TransferFailed();
    error BorrowX__AmountExceedsBalance();
    error BorrowX__NeedsMoreThanZero();
    error BorrowX__MintFailed();

    xUSDC private immutable i_xusdc;

    mapping(address user => uint256 amountCollateral) private collateralDeposited;
    mapping(address user => uint256 amountMinted) private xusdcMinted;

    address private collateralTokenAddress;
    address private priceFeedTokenAddress;

    //////////////////////
    ///Events
    //////////////////////

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralRedeemed(address indexed redeemFrom, address indexed refeemTo, uint256 amount);

    //////////////////////
    ///Modifiers
    //////////////////////

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert BorrowX__NeedsMoreThanZero();
        }
        _;
    }

    //////////////////////
    ///Functions
    //////////////////////

    constructor(address _collateralTokenAddress, address _priceFeedAddress, address _xUSDCAddress) {
        collateralTokenAddress = _collateralTokenAddress;
        priceFeedTokenAddress = _priceFeedAddress;
        i_xusdc = xUSDC(_xUSDCAddress);
    }

    function depositCollateral(uint256 _amount) public moreThanZero(_amount) {
        if (IERC20(collateralTokenAddress).balanceOf(msg.sender) < _amount) revert BorrowX__AmountExceedsBalance();
        collateralDeposited[msg.sender] += _amount;
        bool success = IERC20(collateralTokenAddress).transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert BorrowX__TransferFailed();
        }
    }

    function mintxUSDC(uint256 _amount) public moreThanZero(_amount) {
        //we need to check first if the amount of xUSDC minted exceeds half of the collateral deposited. In this case, they can not mint;
        xusdcMinted[msg.sender] += _amount;
        bool minted = i_xusdc.mint(msg.sender, _amount);
        if (!minted) {
            revert BorrowX__MintFailed();
        }
    }
}
