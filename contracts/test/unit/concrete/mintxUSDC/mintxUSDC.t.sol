//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract mintxUSDCTest is Base_Test {
    uint256 depositAmount = 1 ether;
    uint256 xUSDCMintAmount = 900e18;

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    //////////////////////////
    ///mintxUSDC
    //////////////////////////

    function test_RevertWhen_MintAmountIsZero() public {
        // Make bob the caller of the function
        vm.startPrank(users.bob);

        // Expect the next call to revert with the {BorrowX__NeedsMoreThanZero} error
        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);

        // Run the test
        borrowXContract.mintxUSDC(0);
    }

    function test_RevertWhen_MintAmountBreaksLTV() public {
        // Make bob the caller of the function
        vm.startPrank(users.bob);

        // Bob deposits 1 ether = 2_000 USD so he should be allowed to mint max 1_000 xUSDC
        borrowXContract.depositCollateral{value: depositAmount}();

        // Expect the next call to revert with the {BorrowX__ExceedsLoanToValue} error since bob tries to mint more than 1_001 xUSDC
        vm.expectRevert(BorrowX.BorrowX__ExceedsLoanToValue.selector);

        // Run the test
        borrowXContract.mintxUSDC(1001e18);
    }

    function test_MintXUSDC() public {
        // Make bob caller of the function
        vm.startPrank(users.bob);

        // bob deposits 1 ether so he is able to mint max 1000 xUSDC
        borrowXContract.depositCollateral{value: depositAmount}();

        // Expect the {collateralDeposited} event to be emitted
        vm.expectEmit();
        emit BorrowX.xUSDCMinted(users.bob, xUSDCMintAmount);

        // Run the test
        borrowXContract.mintxUSDC(xUSDCMintAmount);

        // We store the amount of xUSDC bob minted according to the storage
        uint256 bobMinted = borrowXContract.getUserMintedXUSDC(users.bob);

        // We store bob's xUSDC balance from the xUSDC contract
        uint256 bobXUSDCBalance = xUSDCContract.balanceOf(users.bob);

        // Assert the storage is updated according to the amount minted
        assertEq(bobMinted, xUSDCMintAmount);

        // Assert xUSDC has been transfered to bob
        assertEq(bobXUSDCBalance, xUSDCMintAmount);
    }
}
