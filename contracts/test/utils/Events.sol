// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice Abstract contract to store all the events emitted in the tested contracts

abstract contract Events {
    ///@notice Emitted when collateral is deposited into the protocol
    ///@param user The user who deposits
    ///@param amount The amount user deposits
    event CollateralDeposited(address indexed user, uint256 amount);

    ///@notice Emitted when collateral is withdrawn from the protocol
    ///@notice redeemFrom and redeemTo only differ in case of a liquidation
    ///@param redeemFrom The address which initially deposits the collateral
    ///@param redeemTo The address where the collateral is sent
    ///@param amount The amount of collateral
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, uint256 amount);

    ///@notice Emitted when xUSDC token is minted
    ///@param user The user who mints xUSDC
    ///@param amount amount of xUSDC minted
    event xUSDCMinted(address indexed user, uint256 amount);

    ///@notice Emitted when xUSDC was burnt. from differ from onBehalfOf in case of a liquidation
    ///@param from The adress that burns xUSDC
    ///@param onBehalfOf The address which benefits
    ///@param amount The amount of xUSDC burnt
    event xUSDCBurnt(address indexed from, address indexed onBehalfOf, uint256 amount);
}
