// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICurveAdapter {
    event PathWhitelisted(address indexed tokenIn, address indexed tokenOut);
    event PathBlacklisted(address indexed tokenIn, address indexed tokenOut);

    error PathNotWhitelisted(bytes32 pathKey);
    error ZeroAddress();

    struct SwapLocalVariables {
        bytes32 pathKey;
        address[11] route;
        uint256[5][5] swapParams;
        address[5] pools;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 deltaTokenOut;
    }

    /**
     * @notice Returns the address of the Curve router contract
     * @return The address of the Curve router
     */
    function curveRouter() external view returns (address);

    /**
     * @notice Returns whether a swap path is whitelisted
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @param route The route of the swap
     * @param swapParams The swap parameters
     * @param pools The pools of the swap
     * @return Whether the path is whitelisted
     */
    function whitelistedPaths(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) external view returns (bool);

    /**
     * @notice Whitelists a swap path for a token pair with a specific fee tier
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @param route The route of the swap
     * @param swapParams The swap parameters
     * @param pools The pools of the swap
     * @dev Only callable by accounts with WHITELIST_MANAGER_ROLE
     * @dev Emits PathWhitelisted event
     */
    function whitelistPath(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) external;

    /**
     * @notice Blacklists a swap path for a token pair with a specific fee tier
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @param route The route of the swap
     * @param swapParams The swap parameters
     * @param pools The pools of the swap
     * @dev Only callable by accounts with WHITELIST_MANAGER_ROLE
     * @dev Emits PathBlacklisted event
     */
    function blacklistPath(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) external;
}
