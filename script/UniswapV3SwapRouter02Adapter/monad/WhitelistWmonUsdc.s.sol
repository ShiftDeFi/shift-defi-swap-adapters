// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {UniswapV3SwapRouter02Adapter} from "contracts/UniswapV3SwapRouter02Adapter.sol";
import {IUniswapV3SwapRouter02Adapter} from "contracts/interfaces/IUniswapV3SwapRouter02Adapter.sol";

/// @dev Whitelists the predefined WMON -> USDC route (fee 3000) on an
/// already-deployed adapter. The broadcaster must hold WHITELIST_MANAGER_ROLE;
/// the script checks that before calling `whitelistPath`.
contract WhitelistWmonUsdcScript is Script {
    address public constant WMON = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;
    address public constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
    uint24 public constant FEE = 3000;

    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");

    function run() public {
        UniswapV3SwapRouter02Adapter adapter =
            UniswapV3SwapRouter02Adapter(vm.envAddress("UNISWAP_V3_SWAP_ROUTER_02_CONTRACT"));

        address[] memory tokens = new address[](2);
        tokens[0] = WMON;
        tokens[1] = USDC;

        uint24[] memory fees = new uint24[](1);
        fees[0] = FEE;

        vm.startBroadcast();

        require(
            adapter.hasRole(WHITELIST_MANAGER_ROLE, msg.sender),
            IUniswapV3SwapRouter02Adapter.NotWhitelistManager(msg.sender)
        );

        bytes memory path = adapter.whitelistPath(tokens, fees);
        console.log("WMON -> USDC path whitelisted:");
        console.logBytes(path);

        vm.stopBroadcast();
    }
}
