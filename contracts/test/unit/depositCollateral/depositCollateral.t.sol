//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import {xUSDC} from "../../../src/xUSDC.sol";
import {BorrowX} from "../../../src/BorrowX.sol";

contract depositCollateralTest is Test {
    BorrowX public borrowXContract;
    xUSDC public xUSDCContract;

    ethPriceFeedAddress = "0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1";
    address public owner = address(1);
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() {
        //deploy contracts
        xUSDC = new xUSDCContract();
        borrowXContract = new BorrowX();
        // _collateralTokenAddress, address _priceFeedAddress, address _xUSDCAddres
    }
}
