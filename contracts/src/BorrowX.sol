//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {xUSDC} from "./xUSDC.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/// @title BorrowX - A borrowing DeFi protocol
/// @author AlinCiprian
/// @notice This contract allows users to borrow xUSDC against collateral(wETH); Loan-to-Value will be 50%, meaning that
/// users cand borrow half the value that they lock in the contract. Liquidation threshold will be 80% and it is the point where
/// a position is listed for liquidation. In order to incentivize other users to liquidate the position, the liquidator will receive
/// 10% discount on the collateral.
/// @notice The system is meant to be overcollateralized at all times.
/// xUSDC is backed all the time by an equivalent amount in ETH in order to mantain 1:1 USD ratio.

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
    error BorrowX__InsuficientBalance();
    error BorrowX__UserHasSufficientCollateral();
    error BorrowX__DebtWasNotPaid();

    //////////////////////
    ///Types
    //////////////////////
    using OracleLib for AggregatorV3Interface;

    //////////////////////
    ///State variables
    //////////////////////
    xUSDC private immutable i_xusdc;

    uint256 private constant LOAN_TO_VALUE = 50; // 1:2 -> Loan:Value ratio
    uint256 private constant LOAN_LIQUIDATION_DISCOUNT = 10; // 10% discount incentive
    // if xUSDC minted reaches 80% of the collateral deposited, the position is open of liquidation;
    uint256 private constant LOAN_LIQUIDATION_THRESHOLD = 80;
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
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, uint256 amount);
    event xUSDCMinted(address indexed user, uint256 amount);
    event xUSDCBurnt(address indexed user, uint256 amount);

    //////////////////////
    ///Modifiers
    //////////////////////

    /// @notice - used to ensure input is not zero
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

    //////////////////////
    ///Public functions
    //////////////////////

    /// @notice This function allows user to deposit collateral
    /// @param _amountToDeposit - The amount of collateral to be deposited
    function depositCollateral(uint256 _amountToDeposit) public payable moreThanZero(_amountToDeposit) {
        _depositCollateral(_amountToDeposit);
    }

    /// @notice This function allows users to mint xUSDC;
    /// @notice First we check if the desired amount to be minted is allowed by the protocol; then we update the database and mint;
    /// @notice CEI pattern being used to avoid reentrancy;
    function mintxUSDC(uint256 _amountToMint) public moreThanZero(_amountToMint) {
        _checkLoanToValue(_amountToMint, 0);
        xusdcMinted[msg.sender] += _amountToMint;
        bool minted = i_xusdc.mint(msg.sender, _amountToMint);
        if (!minted) {
            revert BorrowX__MintFailed();
        }

        emit xUSDCMinted(msg.sender, _amountToMint);
    }

    /// @notice This function allows user to deposit collateral and automatically mint the maximum  amount of xUSDC
    function depositAndMintMax(uint256 _amountToDeposit) public payable moreThanZero(_amountToDeposit) {
        _depositCollateral(_amountToDeposit);
        uint256 maxMint = _mintAmountAllowed(msg.sender);
        mintxUSDC(maxMint);
    }

    /// @notice This function allows withdrawal of funds assuming protocol conditions are met;
    function withdrawCollateral(uint256 _amountToWithdraw) public moreThanZero(_amountToWithdraw) {
        // we check if the desired operation breaks Loan-To-Value
        _checkLoanToValue(0, _amountToWithdraw);

        // update storage
        collateralDeposited[msg.sender] -= _amountToWithdraw;

        // execute transfer
        (bool success,) = msg.sender.call{value: _amountToWithdraw}("");
        if (!success) revert BorrowX__TransferFailed();
        emit CollateralRedeemed(msg.sender, msg.sender, _amountToWithdraw);
    }

    /// @notice Function allows user to pay the debt and get collateral back;
    /// @dev it can only be called once all the debt is paid
    function closePosition() public {
        // step 1 user burns the entire debt
        burnxUSDC(xusdcMinted[msg.sender]);

        // step 2 we double check that the debt is indeed paid
        if (xusdcMinted[msg.sender] > 0) revert BorrowX__MustPayDebtFirst();

        // step 3 execute the transfer of funds
        uint256 amountToSend = collateralDeposited[msg.sender];
        withdrawCollateral(amountToSend);
    }

    /// @notice This function allows users to liquidate positions that become too undercolllateralized;
    /// @notice As incentive for liquidation, the liquidator gets a 10% discount on the collateral;
    function liquidate(address _userForLiquidation) public {
        // we check if user is eligible to be liquidated;
        bool eligibleForLiquidation = _isEligibleForLiquidation(_userForLiquidation);
        if (eligibleForLiquidation) revert BorrowX__UserHasSufficientCollateral();

        //xUSDC amount to be paid by the liquidator;
        uint256 debtToBePaid = xusdcMinted[_userForLiquidation];
        // token amount of the xUSDC debt;
        uint256 tokenAmountOfDebt = _getTokenAmountFromUsd(debtToBePaid);
        // we calculate the 10% bonus for the liquidator;
        uint256 tokenLiquidationBonus = (tokenAmountOfDebt * LOAN_LIQUIDATION_DISCOUNT) / LOAN_PRECISION;
        uint256 tokenAmountToBeSent = tokenAmountOfDebt + tokenLiquidationBonus;

        //step 1 -> the liquidator burns the amount of xUSDC owned by the user ;
        _burnxUSDC(debtToBePaid, _userForLiquidation, msg.sender);
        //step 2 -> the liquidator gets the equivalent token collateral + 10%;
        (bool success,) = msg.sender.call{value: tokenAmountToBeSent}("");
        if (!success) revert BorrowX__TransferFailed();
        // check if indeed user debt was paid;
        if (xusdcMinted[_userForLiquidation] > 0) revert BorrowX__DebtWasNotPaid();
        emit CollateralRedeemed(_userForLiquidation, msg.sender, tokenAmountToBeSent);
    }

    /// @notice Users can use this function in order to burn their xUSDC.
    /// @notice Might want to use this if you are getting too close to liquidation threshold;
    /// @notice Used by a user to burn xUSDC on his own behalf
    function burnxUSDC(uint256 _amountToBurn) public moreThanZero(_amountToBurn) {
        _burnxUSDC(_amountToBurn, msg.sender, msg.sender);
    }

    //////////////////////
    ///Internal functions
    //////////////////////

    /// @notice The core function that handles xUSDC burning
    function _burnxUSDC(uint256 _amountToBurn, address _beneficiary, address _xUSDCfrom) internal {
        xusdcMinted[_beneficiary] -= _amountToBurn;
        bool success = i_xusdc.transferFrom(_xUSDCfrom, address(this), _amountToBurn);
        if (!success) revert BorrowX__TransferFailed();
        i_xusdc.burn(_amountToBurn);
        emit xUSDCBurnt(_beneficiary, _amountToBurn);
    }

    /// @notice The function is used to deposit collateral;
    function _depositCollateral(uint256 _amountToDeposit) internal moreThanZero(_amountToDeposit) {
        collateralDeposited[msg.sender] += _amountToDeposit;
        (bool success,) = address(this).call{value: _amountToDeposit}("");
        if (!success) revert BorrowX__TransferFailed();
        emit CollateralDeposited(msg.sender, _amountToDeposit);
    }

    //////////////////////
    ///Internal view
    //////////////////////

    /// @notice This functions checks if a position exceeds the liquidation threshold;
    function _isEligibleForLiquidation(address _user) internal view returns (bool) {
        if (xusdcMinted[_user] == 0) return false;
        // How much collateral is deposited by the user
        uint256 userCollateralAmount = collateralDeposited[_user];
        // The usd value of the collateral deposited
        uint256 usdCollateralValue = _getUsdValueFromToken(userCollateralAmount);
        // The amount of xUSDC minted
        uint256 xUSDCDebt = xusdcMinted[_user];
        // we check if the debt reaches 80% of the usd collateral value
        return bool(usdCollateralValue * LOAN_LIQUIDATION_THRESHOLD < xUSDCDebt * LOAN_PRECISION);
    }

    /// @dev This functions checks if the minting or withdraw operation will  break Loan-to-value threshold;
    /// Function must revert if 1:2 ratio is reached;
    /// @param _amountToMint Will be zero if user just tries to withdraw;
    /// @param _amountToWithdraw Will be zero if user just tries to mint;
    function _checkLoanToValue(uint256 _amountToMint, uint256 _amountToWithdraw) internal view {
        if (xusdcMinted[msg.sender] == 0) return; // early return in case use has no debt
        if (_amountToWithdraw > collateralDeposited[msg.sender]) revert BorrowX__InsuficientBalance();
        uint256 userCollateralAmount = collateralDeposited[msg.sender] - _amountToWithdraw;
        uint256 usdValueOfCollateral = _getUsdValueFromToken(userCollateralAmount);
        uint256 totalMintedAfter = xusdcMinted[msg.sender] + _amountToMint;
        if ((usdValueOfCollateral * LOAN_TO_VALUE) < (totalMintedAfter * LOAN_PRECISION)) {
            revert BorrowX__ExceedsLoanToValue();
        }
    }

    /// @notice This function is meant to compute the USD value of the collateral
    function _getUsdValueFromToken(uint256 _amount) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedCollateralTokenAddress);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        /// The price is returned with 8 decimals so we will multiple by 1e10 for additional precision.
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * _amount) / PRECISION;
    }

    /// @notice This function is meant to compute the token value out of USD value
    function _getTokenAmountFromUsd(uint256 _amount) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedCollateralTokenAddress);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return ((_amount * PRECISION) / (uint256(price) / ADDITIONAL_FEED_PRECISION));
    }

    /// @notice This function is used to compute the maximum amount of xUSDC a user can mint.
    /// @notice Takes into account the collateral value and the amount already minted;
    function _mintAmountAllowed(address _user) internal view returns (uint256) {
        uint256 usdCollateralValue = _getUsdValueFromToken(collateralDeposited[_user]);
        uint256 maxUSDCLoanToValue = (usdCollateralValue * LOAN_TO_VALUE) / LOAN_PRECISION;
        uint256 currentlyMinted = xusdcMinted[_user];
        return (maxUSDCLoanToValue - currentlyMinted);
    }

    /// @notice This function is used to compute the maximum amount of collateral a user can withdraw from his position
    function _withdrawAmountAllowed(address _user) internal view returns (uint256) {
        // The amount of USDC minted;
        uint256 currentlyMinted = xusdcMinted[_user];
        // Token amount of the usdc minted;
        uint256 tokenAmountOfxUSDCMinted = _getTokenAmountFromUsd(currentlyMinted);
        // How much token collateral user actually have;
        uint256 userCollateral = collateralDeposited[_user];
        // the difference between 50% of token collateral and the token value of xUSDC minted can be withdrawn without breaking LTV;
        uint256 tokenAmountToWithdraw = (userCollateral * LOAN_TO_VALUE / LOAN_PRECISION) - tokenAmountOfxUSDCMinted;
        return (tokenAmountToWithdraw);
    }

    //////////////////////
    ///Public view
    //////////////////////

    function getMintAmountAllowed(address _user) public view returns (uint256) {
        uint256 mintAmountAllowed = _mintAmountAllowed(_user);
        return mintAmountAllowed;
    }

    function getWithdrawAmountAllowed(address _user) public view returns (uint256) {
        uint256 withdrawAmountAllowed = _withdrawAmountAllowed(_user);
        return withdrawAmountAllowed;
    }

    function getUserCollateralDeposited(address _user) public view returns (uint256) {
        return collateralDeposited[_user];
    }

    function getUserMintedXUSDC(address _user) public view returns (uint256) {
        return xusdcMinted[_user];
    }

    function getLiquidationStatus(address _user) public view returns (bool) {
        bool liquidationStatus = _isEligibleForLiquidation(_user);
        return liquidationStatus;
    }
}
