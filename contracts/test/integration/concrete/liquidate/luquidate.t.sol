//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";
import {Errors} from "../../../utils/Errors.sol";
import {Events} from "../../../utils/Events.sol";
import {MockFailedTransfer} from "../../../mock/MockFailedTransfer.sol";
import {console} from "forge-std/Test.sol";

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;
    /// Ether value from Mock price feed is 2_000 . Given LTV is 50% , max xUSDC mint amount is 1_000 xUSDC
    uint256 MAXxUSDCMintAmount = 1000e18;
    int256 ethUsdUpdatedPrice = 1250e8; // 1 eth = 1250;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Bob deposits some collateral into the protocol
        vm.startPrank(users.bob);
        borrowXContract.depositCollateral{value: depositAmount}();

        // Bob  mints the max amount of xUSDC valaible
        borrowXContract.mintxUSDC(MAXxUSDCMintAmount);

        // We approve borrowXContract for xUSDC spending
        xUSDCContract.approve(address(borrowXContract), type(uint256).max);

        vm.stopPrank();

        vm.prank(users.liquidator);
        // We approve borrowXContract for xUSDC spending
        xUSDCContract.approve(address(borrowXContract), type(uint256).max);
    }

    function test_RevertWhen_UserIsNotEligibleForLiquidation() public {
        // Make liquidator the caller
        vm.startPrank(users.liquidator);

        // Expect the next call to revert with the {BorrowX__UserHasSufficientCollateral} event
        vm.expectRevert(Errors.BorrowX__UserHasSufficientCollateral.selector);

        // Run the test
        borrowXContract.liquidate(users.bob);
    }

    function test_liquidate() public {
        // Make liquidator the caller
        vm.startPrank(users.liquidator);

        // Get the eth balance of liquidator before
        uint256 liquidatorETHBalanceBefore = users.liquidator.balance;

        // We update the price of ethereum to be 1250 - this is the level where bob is eligible for liquidation
        MockV3AggregatorContract.updateAnswer(ethUsdUpdatedPrice);

        (, int256 price,,,) = MockV3AggregatorContract.latestRoundData();
        console.log("price feed price", price);

        // Compute the amount of collateral liquidator should get after liquidation without bonus
        // We divide the amount of xUSDC liquidator is requested to burn by the price of eth and we get how much eth liquidator is entitled to
        uint256 ethAmountWithoutBonus = (MAXxUSDCMintAmount * 1e8) / uint256(price);
        console.log("withouBOnus", ethAmountWithoutBonus);
        // We add the 10% bonus
        uint256 bonusETH = (ethAmountWithoutBonus * Constants.LOAN_LIQUIDATION_DISCOUNT) / Constants.LOAN_PRECISION;
        // The total amount of ETH that the liquidator should get
        uint256 liquidatorShouldGet = (ethAmountWithoutBonus + bonusETH);
        console.log("amount to be sent", liquidatorShouldGet);

        //We expect the {CollateralRedeemed} event to be emitted
        vm.expectEmit();
        emit CollateralRedeemed(users.bob, users.liquidator, liquidatorShouldGet);

        // Run the test
        borrowXContract.liquidate(users.bob);

        // Get the amount of collateral deposited for Bob
        uint256 bobCollateralDeposited = borrowXContract.getUserCollateralDeposited(users.bob);
        // Get the amount of xUSDCMinted from storage
        uint256 bobXUSDCMinted = borrowXContract.getUserMintedXUSDC(users.bob);

        // Get the xUSDC balance of borrowXContract
        uint256 xUSDCBalance = xUSDCContract.balanceOf(address(borrowXContract));

        // We assert that the storage is updated
        assertEq(bobCollateralDeposited, 0);
        assertEq(bobXUSDCMinted, 0);

        // We assert that the xUSDC was burn
        assertEq(xUSDCBalance, 0);

        // We assert that the correct amount of collateral is sent
        assertEq(users.liquidator.balance, liquidatorShouldGet + liquidatorETHBalanceBefore);
    }
}
