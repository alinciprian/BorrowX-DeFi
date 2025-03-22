//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract constructorInitTest is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    function test_constructorInit() public view {
        assertEq(borrowXContract.priceFeedCollateralTokenAddress(), address(MockV3AggregatorContract));
        xUSDC xUSDCContract = borrowXContract.i_xusdc();
        assertEq(address(xUSDCContract), address(xUSDCContract));
    }
}
