// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {SwapRouter} from "@shift-defi/core/SwapRouter.sol";
import {ISwapRouter} from "@shift-defi/core/interfaces/ISwapRouter.sol";

import {UniswapV3SwapRouter02Adapter} from "contracts/UniswapV3SwapRouter02Adapter.sol";
import {IUniswapV3SwapRouter02Adapter} from "contracts/interfaces/IUniswapV3SwapRouter02Adapter.sol";

import {Base} from "test/Base.t.sol";

/// @dev Path-encoding is network-agnostic, so this suite stays hermetic: mock
/// tokens and a placeholder Uniswap router address (never actually called
/// here). `shiftSwapRouter` is a real, deployed core-package `SwapRouter`
/// though, not a placeholder - the adapter is whitelisted on it, matching how
/// it's actually reached in production. See test/fork/ for tests against a
/// real, network-specific SwapRouter02 + pool.
contract UniswapV3SwapRouter02AdapterBase is Base {
    IUniswapV3SwapRouter02Adapter internal uniswapV3Adapter;

    ERC20Mock internal tokenA;
    ERC20Mock internal tokenB;

    uint24 internal constant FEE = 3000;

    function setUp() public virtual override {
        super.setUp();

        shiftSwapRouter = _deployShiftSwapRouter();
        vm.label(shiftSwapRouter, "SHIFT_SWAP_ROUTER");

        tokenA = new ERC20Mock();
        vm.label(address(tokenA), "TOKEN_A");
        tokenB = new ERC20Mock();
        vm.label(address(tokenB), "TOKEN_B");

        uniswapV3Adapter = new UniswapV3SwapRouter02Adapter(roles.defaultAdmin, makeAddr("SWAP_ROUTER_02"));
        vm.label(address(uniswapV3Adapter), "UNISWAP_V3_SWAP_ROUTER_02");

        vm.prank(roles.defaultAdmin);
        AccessControl(address(uniswapV3Adapter)).grantRole(WHITELIST_MANAGER_ROLE, roles.whitelistManager);

        vm.prank(roles.whitelistManager);
        ISwapRouter(shiftSwapRouter).whitelistSwapAdapter(address(uniswapV3Adapter));
    }

    function _deployShiftSwapRouter() internal returns (address) {
        address implementation = address(new SwapRouter());
        return address(
            new TransparentUpgradeableProxy(
                implementation,
                roles.defaultAdmin,
                abi.encodeWithSelector(SwapRouter.initialize.selector, roles.defaultAdmin, roles.whitelistManager)
            )
        );
    }

    function _whitelistPath() internal returns (bytes memory path) {
        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);

        uint24[] memory fees = new uint24[](1);
        fees[0] = FEE;

        vm.prank(roles.whitelistManager);
        path = uniswapV3Adapter.whitelistPath(tokens, fees);
    }
}
