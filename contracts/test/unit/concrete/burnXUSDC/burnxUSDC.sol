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

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;
    /// Ether value from Mock price feed is 2_000 . Given LTV is 50% , max xUSDC mint amount is 1_000 xUSDC
    uint256 MAXxUSDCMintAmount = 1000e18;
    MockFailedTransfer revertContract;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Bob deposits some collateral into the protocol
        vm.startPrank(users.bob);
        borrowXContract.depositCollateral{value: depositAmount}();

        // Bob  mints the max amount of xUSDC valaible
        borrowXContract.mintxUSDC(MAXxUSDCMintAmount);
        vm.stopPrank();
    }

    function test_revertWhen_burnAmountIsZero() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // Expect the next call to revert with {BorrowX__NeedsMoreThanZero}
        vm.expectRevert(Errors.BorrowX__NeedsMoreThanZero.selector);

        // Run the test
        borrowXContract.burnxUSDC(0);
    }
}
