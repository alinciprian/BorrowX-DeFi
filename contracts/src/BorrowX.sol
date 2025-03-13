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
    error BorrowX__ExceedsLoanToValue();
    error BorrowX__MustPayDebtFirst();

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
    uint256 private constant LOAN_LIQUIDATION_THRESHOLD = 75;
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

    /// @param _collateralTokenAddress - the address of the token that will be used as collateral
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

    /// This function allows users to mint xUSDC
    /// First we check if the desired amount to be minted is allowed by the protocol; then we update the database and mint
    /// CEI pattern being used to avoid reentrancy
    function mintxUSDC(uint256 _amountToMint) public moreThanZero(_amountToMint) {
        _checkLoanToValue(msg.sender, _amountToMint, 0);
        xusdcMinted[msg.sender] += _amountToMint;
        bool minted = i_xusdc.mint(msg.sender, _amountToMint);
        if (!minted) {
            revert BorrowX__MintFailed();
        }
    }

    function withdrawCollateral(uint256 _amountToWithdraw) public moreThanZero(_amountToWithdraw) {
        // we check if the desired operation breaks Loan-To-Value
        _checkLoanToValue(msg.sender, 0, _amountToWithdraw);

        // update storage
        collateralDeposited[msg.sender] -= _amountToWithdraw;

        // execute transfer
        bool success = IERC20(collateralTokenAddress).transfer(msg.sender, _amountToWithdraw);
        if (!success) revert BorrowX__TransferFailed();
    }

    /// Users can use this function in order to burn their xUSDC. Might want to do this if you are getting too close to liquidation threshold
    function burnxUSDC(uint256 _amountToBurn) public moreThanZero(_amountToBurn) {
        _burnDsc(_amountToBurn, msg.sender, msg.sender);
    }

    /// This function allows user to deposit collateral and automatically mint the maximum allowed amount of xUSDC
    function depositAndMintMax(uint256 _amountToDeposit) public moreThanZero(_amountToDeposit) {
        depositCollateral(_amountToDeposit);
        uint256 maxMint = mintAmountAllowed(msg.sender);
        mintxUSDC(maxMint);
    }

    /// Function allows user to pay the debt and get collateral back;
    /// @dev it can only be called once all the debt is paid
    function closePosition() public {
        // step 1 user burns the entire debt
        burnxUSDC(xusdcMinted[msg.sender]);

        // step 2 we double check that the debt is indeed paid
        if (xusdcMinted[msg.sender] > 0) revert BorrowX__MustPayDebtFirst();

        // step 3 update storage
        uint256 amountToSend = collateralDeposited[msg.sender];
        collateralDeposited[msg.sender] = 0;

        // step 4 execute transfer of funds
        bool success = IERC20(collateralTokenAddress).transfer(msg.sender, amountToSend);
        if (!success) revert BorrowX__TransferFailed();
    }

    /// This function is used to compute the maximum amount of xUSDC a user can mint. Takes into account the collateral value and the amount already minted;
    function mintAmountAllowed(address _user) public view returns (uint256) {
        uint256 usdCollateralValue = _getUsdValueFromToken(collateralDeposited[_user]);
        uint256 maxUSDCLoanToValue = (usdCollateralValue * LOAN_TO_VALUE) / LOAN_PRECISION;
        uint256 currentlyMinted = xusdcMinted[_user];
        return (maxUSDCLoanToValue - currentlyMinted);
    }

    /// @dev This functions checks if the minting or withdraw operation will will break Loan-to-value threshold;
    /// Function must revert if 1:2 ratio is exceeded;
    /// @param _amountToMint Will be zero if user just tries to withdraw;
    /// @param _amountToWithdraw Will be zero if user just tries to mint;
    function _checkLoanToValue(address _user, uint256 _amountToMint, uint256 _amountToWithdraw) internal view {
        uint256 userCollateralAmount = collateralDeposited[_user] - _amountToWithdraw;
        uint256 usdValueOfCollateral = _getUsdValueFromToken(userCollateralAmount);
        uint256 totalMintedAfter = xusdcMinted[_user] + _amountToMint;
        if ((usdValueOfCollateral * LOAN_TO_VALUE) / LOAN_PRECISION <= totalMintedAfter) {
            revert BorrowX__ExceedsLoanToValue();
        }
    }

    /// The core function that handles xUSDC burning
    function _burnDsc(uint256 _amountToBurn, address _beneficiary, address _xUSDCfrom) private {
        xusdcMinted[_beneficiary] -= _amountToBurn;
        bool success = i_xusdc.transferFrom(_xUSDCfrom, address(this), _amountToBurn);
        if (!success) revert BorrowX__TransferFailed();
        i_xusdc.burn(_amountToBurn);
    }

    /// The function is meant to compute the USD value of the collateral
    function _getUsdValueFromToken(uint256 _amount) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedCollateralTokenAddress);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        /// The price is returned with 8 decimals so we will multiple by 1e10 for additional precision.
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * _amount) / PRECISION;
    }
}
