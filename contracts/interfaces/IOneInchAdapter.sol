// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IOneInchAdapter {
    error NotRouter(address sender);
    error InvalidSelector(bytes4 selector);
    error InvalidSourceToken(address token);
    error InvalidDestinationToken(address token);
    error InvalidAmountIn(uint256 amount);
    error InvalidMinAmountOut(uint256 amount);
    error InvalidSrcReceiver(address receiver);

    /**
     * @notice Returns the address of the 1inch router contract
     * @return The immutable address of the 1inch router
     */
    function oneInchRouter() external view returns (address);
}
