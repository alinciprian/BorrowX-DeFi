//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {xUSDC} from "./xUSDC.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/// @title BorrowX
/// @author AlinCiprian
/// @notice This contract allows users to borrow xUSDC against collateral(wETH); Loan-to-Value will be 50%, meaning that
/// users cand borrow half the value that they lock in the contract. Liquidation threshold will be 75% and it is the point where
/// a position is listed for liquidation. In order to incentivize other users to liquidate the position, the liquidator will receive
/// 10% discount on the collateral.
/// @notice The system is meant to be overcollateralized at all times.
/// xUSDC is backed all the time by an equivalent amount in wETH in order to mantain 1:1 USD ratio.

contract BorrowX is ReentrancyGuard {
    //////////////////////
    ///Errors
    //////////////////////
    error BorrowX__TransferFailed();
    error BorrowX__AmountExceedsBalance();
    error BorrowX__NeedsMoreThanZero();
    error BorrowX__MintFailed();
    error BorrowX__MintAmountExceedsLoanToValue();

    //////////////////////
    ///Types
    //////////////////////
    using OracleLib for AggregatorV3Interface;

    //////////////////////
    ///Types
    //////////////////////
    xUSDC private immutable i_xusdc;

    uint256 private constant LOAN_TO_VALUE = 50; // 1:2 -> Loan:Value ratio
    uint256 private constant LOAN_LIQUIDATION_DISCOUNT = 10; // 10% discount incentive
    uint256 private constant LOAN_PRECISION = 100;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;

    mapping(address user => uint256 amountCollateral) private collateralDeposited;
    mapping(address user => uint256 amountMinted) private xusdcMinted;

    address private collateralTokenAddress;
    address private priceFeedCollateralTokenAddress;

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

    /// @param _collateralTokenAddress - the address of the token that will be used as collateral(wETH)
    /// @param _priceFeedAddress - the priceFeed address of the token used as collateral
    /// @param _xUSDCAddress - the address of the xUSDC contract
    constructor(address _collateralTokenAddress, address _priceFeedAddress, address _xUSDCAddress) {
        collateralTokenAddress = _collateralTokenAddress;
        priceFeedCollateralTokenAddress = _priceFeedAddress;
        i_xusdc = xUSDC(_xUSDCAddress);
    }

    /// This function allows user to deposit collateral
    /// @param _amount - The amount of collateral to be deposited
    function depositCollateral(uint256 _amount) public moreThanZero(_amount) {
        if (IERC20(collateralTokenAddress).balanceOf(msg.sender) < _amount) revert BorrowX__AmountExceedsBalance();
        collateralDeposited[msg.sender] += _amount;
        bool success = IERC20(collateralTokenAddress).transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert BorrowX__TransferFailed();
        }
    }

    function mintxUSDC(uint256 _amount) public moreThanZero(_amount) {
        _checkLoanToValue(msg.sender, _amount);
        xusdcMinted[msg.sender] += _amount;
        bool minted = i_xusdc.mint(msg.sender, _amount);
        if (!minted) {
            revert BorrowX__MintFailed();
        }
    }

    function _checkLoanToValue(address _user, uint256 _amount) internal view {
        uint256 userCollateralAmount = collateralDeposited[_user];
        uint256 usdValueOfCollateral = _getUsdValueFromToken(userCollateralAmount);
        uint256 totalMintedAfter = xusdcMinted[_user] + _amount;
        if ((usdValueOfCollateral * LOAN_TO_VALUE) / LOAN_PRECISION <= totalMintedAfter) {
            revert BorrowX__MintAmountExceedsLoanToValue();
        }
        //this function should get the USD value of the collateral and compare it to the amount of xUSDC minted by the user
        //In order to do this, we need to use chainlink priceFeeds.
    }

    /// The function is meant to compute the USD value of the collateral
    function _getUsdValueFromToken(uint256 _amount) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedCollateralTokenAddress);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        /// The price is returned with 8 decimals so we will multiple by 1e10 for additional precision.
        return ((uint256(price) * 1e10) * _amount) / PRECISION;
    }
}
