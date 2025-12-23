// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICustomPool {
    error InvalidDenominator();
    error PriceNotSet();
    error ReservesExceeded(uint256 amountOut, uint256 reserve);
    event SetPrice(address indexed tokenIn, address indexed tokenOut, uint256 numerator, uint256 denominator);

    struct Price {
        uint256 numerator;
        uint256 denominator;
    }
}
