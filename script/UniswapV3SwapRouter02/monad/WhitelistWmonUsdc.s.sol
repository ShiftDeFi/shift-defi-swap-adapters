// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {UniswapV3SwapRouter02} from "contracts/UniswapV3SwapRouter02.sol";

/// @dev Grants WHITELIST_MANAGER_ROLE and whitelists the predefined WMON ->
/// USDC route (fee 3000) on an already-deployed adapter. The broadcaster must
/// hold DEFAULT_ADMIN_ROLE on the adapter to grant the role, and
/// WHITELIST_MANAGER_ROLE to whitelist the path.
contract WhitelistWmonUsdcScript is Script {
    address public constant WMON = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;
    address public constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
    uint24 public constant FEE = 3000;

    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");

    function run() public {
        UniswapV3SwapRouter02 adapter = UniswapV3SwapRouter02(vm.envAddress("UNISWAP_V3_SWAP_ROUTER_02_CONTRACT"));
        address whitelistManager = vm.envAddress("WHITELIST_MANAGER");

        address[] memory tokens = new address[](2);
        tokens[0] = WMON;
        tokens[1] = USDC;

        uint24[] memory fees = new uint24[](1);
        fees[0] = FEE;

        vm.startBroadcast();

        adapter.grantRole(WHITELIST_MANAGER_ROLE, whitelistManager);
        console.log("WHITELIST_MANAGER_ROLE granted to: %s", whitelistManager);

        bytes memory path = adapter.whitelistPath(tokens, fees);
        console.log("WMON -> USDC path whitelisted:");
        console.logBytes(path);

        vm.stopBroadcast();
    }
}
