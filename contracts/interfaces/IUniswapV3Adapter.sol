// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";

interface IUniswapV3Adapter is ISwapAdapter {
    event PathWhitelisted(address indexed tokenIn, address indexed tokenOut, bytes path);
    event PathBlacklisted(address indexed tokenIn, address indexed tokenOut, bytes path);

    error PathNotWhitelisted(bytes path);
    error NotWhitelistManager(address sender);
    error InvalidPathLengths(uint256 expectedLength, uint256 actualLength);

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
     * @dev Only callable by accounts with WHITELIST_MANAGER_ROLE
     * @dev Emits PathWhitelisted event
     * @param tokens The token addresses in the path
     * @param fees The fee tiers for each pool in the path
     * @return path The encoded swap path (tokenIn, fee, tokenOut)
     */
    function whitelistPath(address[] memory tokens, uint24[] memory fees) external returns (bytes memory path);

    /**
     * @notice Decodes a swap path into tokens and fees
     * @param path The encoded swap path (tokenIn, fee, tokenOut)
     * @return tokens The token addresses in the path
     * @return fees The fee tiers for each pool in the path
     */
    function decodePath(bytes memory path) external pure returns (address[] memory tokens, uint24[] memory fees);

    /**
     * @notice Blacklists a swap path for a token pair with a specific fee tier
     * @param path The encoded swap path (tokenIn, fee, tokenOut)
     * @dev Only callable by accounts with WHITELIST_MANAGER_ROLE
     * @dev Emits PathBlacklisted event
     */
    function blacklistPath(bytes calldata path) external;
}
