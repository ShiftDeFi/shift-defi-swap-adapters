// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {UniswapV3SwapRouter02Adapter} from "contracts/UniswapV3SwapRouter02Adapter.sol";

/// @dev Chain-agnostic: the adapter itself has no chain-specific logic, only
/// the SwapRouter02 address it's constructed with does - so that's read from
/// env rather than hardcoded. Pair whitelisting stays chain-specific; see the
/// per-network scripts alongside this one.
contract DeployScript is Script {
    function run() public {
        address defaultAdmin = vm.envAddress("DEFAULT_ADMIN");
        address whitelistManager = vm.envAddress("WHITELIST_MANAGER");
        address swapRouter02 = vm.envAddress("UNISWAP_V3_SWAP_ROUTER_02");

        vm.startBroadcast();
        UniswapV3SwapRouter02Adapter adapter =
            new UniswapV3SwapRouter02Adapter(defaultAdmin, whitelistManager, swapRouter02);
        vm.stopBroadcast();

        console.log("UniswapV3SwapRouter02Adapter deployed at: %s", address(adapter));
    }
}
