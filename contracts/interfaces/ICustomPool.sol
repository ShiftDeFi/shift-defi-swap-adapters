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

    /**
     * @notice Returns the price configuration for a token pair
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @return numerator The price numerator
     * @return denominator The price denominator
     */
    function price(address tokenIn, address tokenOut) external view returns (uint256 numerator, uint256 denominator);

    /**
     * @notice Sets the price for a token pair
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @param numerator The price numerator
     * @param denominator The price denominator (must be greater than 0)
     * @dev Only callable by accounts with TOKEN_MANAGER_ROLE
     */
    function setPrice(address tokenIn, address tokenOut, uint256 numerator, uint256 denominator) external;
}
