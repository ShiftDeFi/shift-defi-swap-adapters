// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";

interface IPyusdUsdcEthereumAdapter is ISwapAdapter {
    /**
     * @notice Returns the amount of USDC that would be received for a given amount of PYUSD using the Spark pool
     * @param amountIn The amount of PYUSD to swap
     * @return amountOut The amount of USDC that would be received
     */
    function getSparkQuoteUsdc(uint256 amountIn) external view returns (uint256 amountOut);

    /**
     * @notice Returns the amount of USDC that would be received for a given amount of PYUSD using the Pay pool
     * @param amountIn The amount of PYUSD to swap
     * @return amountOut The amount of USDC that would be received
     */
    function getPayQuoteUsdc(uint256 amountIn) external view returns (uint256 amountOut);

    error InvalidTokenIn(address tokenIn, address expectedTokenIn);
    error InvalidTokenOut(address tokenOut, address expectedTokenOut);
}
