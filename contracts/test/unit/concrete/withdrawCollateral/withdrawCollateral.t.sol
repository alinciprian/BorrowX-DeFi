//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";
import {Errors} from "../../../utils/Errors.sol";

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;
    uint256 xUSDCMintAmount = 900e18;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Bob deposits some collateral into the protocol
        vm.prank(users.bob);
        borrowXContract.depositCollateral{value: depositAmount}();
    }

    function test_RevertWhen_withdrawAmountIsZero() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // We expect the next call to revert with the {BorrowX__NeedsMoreThanZero} error
        vm.expectRevert(Errors.BorrowX__NeedsMoreThanZero.selector);

        // We run the test
        borrowXContract.withdrawCollateral(0);
    }

    function test_RevertWhen_withdrawAmountExceedsBalance() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // We expect the next call to revert with the {BorrowX__InsuficientBalance} error
        vm.expectRevert(Errors.BorrowX__InsuficientBalance.selector);

        // We run the test
        borrowXContract.withdrawCollateral(depositAmount + 1);
    }
}
