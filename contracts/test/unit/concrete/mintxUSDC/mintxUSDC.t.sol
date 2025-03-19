//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    //////////////////////////
    ///mintxUSDC
    //////////////////////////

    function testItShouldRevertIfMintAmountIsZero() public {
        vm.startPrank(users.bob);

        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);
        borrowXContract.mintxUSDC(0);

        vm.stopPrank();
    }

    function testItShouldRevertIfMintingExceedsLTV() public {
        vm.startPrank(users.bob);

        vm.expectRevert(BorrowX.BorrowX__ExceedsLoanToValue.selector);
        borrowXContract.mintxUSDC(10e18);

        vm.stopPrank();
    }

    function testItShouldUpdateStorageAfterMinting() public {
        vm.deal(users.eve, 1 ether);
        vm.startPrank(users.eve);

        borrowXContract.depositCollateral{value: depositAmount}();
        borrowXContract.mintxUSDC(900e18);

        uint256 aliceMinted = borrowXContract.getUserMintedXUSDC(users.eve);

        assertEq(aliceMinted, 900e18);

        vm.stopPrank();
    }

    function testItShouldTransferFundsAfterMinting() public {
        vm.deal(users.eve, 1 ether);
        vm.startPrank(users.eve);

        borrowXContract.depositCollateral{value: depositAmount}();
        borrowXContract.mintxUSDC(900e18);

        uint256 aliceBalance = xUSDCContract.balanceOf(users.eve);
        assertEq(aliceBalance, 900e18);

        vm.stopPrank();
    }

    function testItShouldEmitEventAfterMinting() public {
        vm.deal(users.eve, 1 ether);
        vm.startPrank(users.eve);

        borrowXContract.depositCollateral{value: depositAmount}();

        vm.expectEmit();
        emit BorrowX.xUSDCMinted(users.eve, 900e18);
        borrowXContract.mintxUSDC(900e18);

        vm.stopPrank();
    }
}
