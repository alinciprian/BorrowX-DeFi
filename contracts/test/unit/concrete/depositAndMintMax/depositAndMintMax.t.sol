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
