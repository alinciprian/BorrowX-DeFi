//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {xUSDC} from "../src/xUSDC.sol";
import {BorrowX} from "../src/BorrowX.sol";
import {Users} from "./utils/Types.sol";
import {Events} from "./utils/Events.sol";
import {Errors} from "./utils/Errors.sol";
import {Constants} from "./utils/Constants.sol";
import {MockV3Aggregator} from "./mock/MockV3Aggregator.sol";

contract Base_Test is Test, Events {
    Users internal users;
    BorrowX public borrowXContract;
    xUSDC public xUSDCContract;
    MockV3Aggregator public MockV3AggregatorContract;
    uint256 adminUSDCStartingBalance = 1000e18; // admin starts with 1000 xUSDC

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        //deploy contracts
        MockV3AggregatorContract = new MockV3Aggregator(Constants.DECIMALS, Constants.ETH_USD_PRICE);
        xUSDCContract = new xUSDC();
        borrowXContract = new BorrowX(address(MockV3AggregatorContract), address(xUSDCContract));

        //Create test users
        users = Users({admin: createUser("admin"), eve: createUser("eve"), bob: createUser("bob")});

        //Mint some starting xUSDC for the admin
        xUSDCContract.mint(users.admin, adminUSDCStartingBalance);

        //Transfers ownership of the xUSDC contract
        xUSDCContract.transferOwnership(address(borrowXContract));

        // Label the test contracts so we can easily track them
        vm.label({account: address(MockV3AggregatorContract), newLabel: "MockV3Aggregator"});
        vm.label({account: address(xUSDCContract), newLabel: "xUSDCContract"});
        vm.label({account: address(borrowXContract), newLabel: "borrowXContract"});
    }

    /// @dev Generates a user, labels its address, and funds it with test assets
    function createUser(string memory name) internal virtual returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 100 ether});
        return user;
    }
}
