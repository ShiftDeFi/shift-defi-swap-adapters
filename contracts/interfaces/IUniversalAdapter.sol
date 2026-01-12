// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IUniversalAdapter {
    struct SwapInfo {
        address router;
        uint256 amountIndex;
        bytes payload;
    }

    event SwapInfoSet(address indexed fromToken, address indexed toToken, SwapInfo swapInfo);

    error NotWhitelistManager(address sender);
    error NoSwapInfo(address fromToken, address toToken);
    error IndexOutOfBounds(uint256 index);

    /**
     * @notice Returns the swap information for a token pair
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @return router The router address to use for the swap
     * @return amountIndex The byte index where the amount should be inserted in the payload
     * @return payload The encoded swap payload
     */
    function swapInfos(
        address tokenIn,
        address tokenOut
    ) external view returns (address router, uint256 amountIndex, bytes memory payload);

    /**
     * @notice Checks if a swap is supported for a token pair
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @return Whether the swap is supported (router is set and payload is not empty)
     */
    function isSwapSupported(address tokenIn, address tokenOut) external view returns (bool);

    /**
     * @notice Sets the swap information for a token pair
     * @param fromToken The input token address
     * @param toToken The output token address
     * @param router The router address to use for the swap
     * @param amountIndex The byte index where the amount should be inserted in the payload
     * @param payload The encoded swap payload
     * @dev Only callable by accounts with WHITELIST_MANAGER_ROLE
     * @dev Emits SwapInfoSet event
     */
    function setSwapInfo(
        address fromToken,
        address toToken,
        address router,
        uint256 amountIndex,
        bytes calldata payload
    ) external;
}
