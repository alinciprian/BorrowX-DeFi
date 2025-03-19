//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {Events} from "../../../utils/Events.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    //////////////////////////
    ///depositCollateral
    //////////////////////////

    function test_RevertWhen_DepositAmountIsZero() public {
        // Make bob the caller of the function
        vm.startPrank(users.bob);

        // Expect the next call to revert with the {BorrowX__NeedsMoreThanZero} error
        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);

        // Run the test
        borrowXContract.depositCollateral{value: 0}();

        vm.stopPrank();
    }

    function test_WhenDepositAmountIsNotZero() public {
        // Make bob the caller of the function
        vm.startPrank(users.bob);

        // Store the balance of bob and the balance of the contract before the deposit
        uint256 contractBalanceBefore = address(borrowXContract).balance;
        uint256 bobBalanceBefore = address(users.bob).balance;

        //Expect the {CollateralDeposited} event to be emitted
        vm.expectEmit();
        emit Events.CollateralDeposited({user: users.bob, amount: depositAmount});

        // Run the test
        borrowXContract.depositCollateral{value: depositAmount}();

        // Store the balance of bob and the balance of the contract after the deposit
        uint256 contractBalanceAfter = address(borrowXContract).balance;
        uint256 bobBalanceAfter = address(users.bob).balance;

        // Get bob's balance of collateral deposited
        uint256 collateralDeposited = borrowXContract.getUserCollateralDeposited(users.bob);

        // Assert the balance of collateral for Bob
        assertEq(collateralDeposited, depositAmount);

        // Assert the ETH balance of Bob and the contract after the deposit
        assertEq(contractBalanceAfter, contractBalanceBefore + depositAmount);
        assertEq(bobBalanceAfter, bobBalanceBefore - depositAmount);
    }

    function test_ItShouldUpdateStorageAfterDeposit() public {
        vm.startPrank(users.bob);

        borrowXContract.depositCollateral{value: depositAmount}();
        uint256 collateralDeposited = borrowXContract.getUserCollateralDeposited(users.bob);
        assertEq(depositAmount, collateralDeposited);

        vm.stopPrank();
    }

    function testItShouldTransferFunds() public {
        vm.startPrank(users.bob);

        uint256 contractBalanceBefore = address(borrowXContract).balance;
        uint256 ownerBalanceBefore = address(users.bob).balance;

        borrowXContract.depositCollateral{value: depositAmount}();

        uint256 contractBalanceAfter = address(borrowXContract).balance;
        uint256 ownerBalanceAfter = address(users.bob).balance;

        assertEq(contractBalanceAfter, contractBalanceBefore + depositAmount);
        assertEq(ownerBalanceAfter, ownerBalanceBefore - depositAmount);

        vm.stopPrank();
    }

    function testItshouldEmitEvent() public {
        vm.startPrank(users.bob);
        vm.expectEmit();
        emit BorrowX.CollateralDeposited(users.bob, depositAmount);
        borrowXContract.depositCollateral{value: depositAmount}();
        vm.stopPrank();
    }

    //////////////////////////
    ///depositAndMintMax
    //////////////////////////

    function testItShouldDepositAndMintMaxAmount() public {
        vm.startPrank(users.eve);

        borrowXContract.depositAndMintMax{value: 2 * depositAmount}();

        uint256 aliceBalance = xUSDCContract.balanceOf(users.eve);
        uint256 ethPrice = uint256(Constants.ETH_USD_PRICE);
        uint256 loan_to_value = Constants.LOAN_TO_VALUE;
        uint256 loan_precision = Constants.LOAN_PRECISION;
        uint256 aliceShouldHave = ((2 * depositAmount * ethPrice * loan_to_value) / loan_precision) / 1e8;

        assertEq(aliceBalance, aliceShouldHave);
    }
}
