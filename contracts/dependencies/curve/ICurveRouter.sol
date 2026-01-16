// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICurveRouter {
    function exchange(
        address[11] memory tokens,
        uint256[5][5] memory swapParams,
        uint256 amount,
        uint256 minAmountOut,
        address[5] memory pools
    ) external;
}
