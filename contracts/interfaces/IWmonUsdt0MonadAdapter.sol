// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";

interface IWmonUsdt0MonadAdapter is ISwapAdapter {
    error InvalidTokenIn(address tokenIn, address expectedTokenIn);
    error InvalidTokenOut(address tokenOut, address expectedTokenOut);
    error PartialFill(uint256 amountIn, uint256 amountInSpent);
    error UnexpectedNativeSender(address sender);
}
