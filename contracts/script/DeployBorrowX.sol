//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {BorrowX} from "../src/BorrowX.sol";
import {xUSDC} from "../src/xUSDC.sol";

contract Deploy is Script {
    address ethUsdPriceFeed = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;

    function run() external returns (xUSDC xUSDCContract, BorrowX borrrowXContract) {
        vm.startBroadcast();

        xUSDCContract = new xUSDC();
        borrrowXContract = new BorrowX(ethUsdPriceFeed, address(xUSDCContract));

        xUSDCContract.transferOwnership(address(borrrowXContract));

        vm.stopBroadcast();
    }
}
