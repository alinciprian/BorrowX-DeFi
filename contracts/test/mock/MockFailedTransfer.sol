// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockFailedTransfer is ERC20Burnable, Ownable {
    error MockFailedTransfer__RevertOnPurpose();

    receive() external payable {
        revert MockFailedTransfer__RevertOnPurpose();
    }

    constructor() ERC20("MockTransferFail", "MTS") Ownable(msg.sender) {}
}
