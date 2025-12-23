// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IUniswapV3Adapter {
    event PathWhitelisted(address indexed tokenIn, address indexed tokenOut, uint24 fee, bytes path);
    event PathBlacklisted(address indexed tokenIn, address indexed tokenOut, uint24 fee, bytes path);

    error PathNotWhitelisted(bytes path);
    error NotWhitelistManager(address sender);

    /**
     * @notice Returns the address of the Uniswap V3 router contract
     * @return The immutable address of the Uniswap V3 router
     */
    function uniswapV3Router() external view returns (address);

    /**
     * @notice Returns whether a swap path is whitelisted
     * @param path The encoded swap path (tokenIn, fee, tokenOut)
     * @return Whether the path is whitelisted
     */
    function whitelistedPaths(bytes calldata path) external view returns (bool);

    /**
     * @notice Whitelists a swap path for a token pair with a specific fee tier
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @param fee The fee tier (e.g., 3000 for 0.3%)
     * @dev Only callable by accounts with WHITELIST_MANAGER_ROLE
     * @dev Emits PathWhitelisted event
     */
    function whitelistPath(address tokenIn, address tokenOut, uint24 fee) external;

    /**
     * @notice Blacklists a swap path for a token pair with a specific fee tier
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @param fee The fee tier (e.g., 3000 for 0.3%)
     * @dev Only callable by accounts with WHITELIST_MANAGER_ROLE
     * @dev Emits PathBlacklisted event
     */
    function blacklistPath(address tokenIn, address tokenOut, uint24 fee) external;
}
