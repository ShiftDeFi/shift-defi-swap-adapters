// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CurveAdapter} from "contracts/CurveAdapter.sol";
import {EthereumBase} from "test/ethereum/EthereumBase.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveAdapterTest is EthereumBase {
    using SafeERC20 for IERC20;

    CurveAdapter internal curveAdapter;

    function setUp() public override {
        super.setUp();

        curveAdapter = new CurveAdapter(roles.defaultAdmin, CURVE_ROUTER, roles.whitelistManager);
        vm.label(address(curveAdapter), "CURVE_ADAPTER");
    }

    function _whitelistPath(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) private {
        vm.prank(roles.whitelistManager);
        curveAdapter.whitelistPath(tokenIn, tokenOut, route, swapParams, pools);
        assertTrue(curveAdapter.whitelistedPaths(tokenIn, tokenOut, route, swapParams, pools));
    }

    function _input()
        private
        pure
        returns (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams)
    {
        route = [
            WETH,
            CURVE_TRICRYPTO_OPTIMIZED_WETH,
            CRVUSD,
            SUSDE_CRVUSD_POOL,
            SUSDE,
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0)
        ];
        pools = [CURVE_TRICRYPTO_OPTIMIZED_WETH, SUSDE_CRVUSD_POOL, address(0), address(0), address(0)];
        swapParams = [
            [uint256(1), 0, 1, 30, 3],
            [uint256(0), 1, 1, 10, 2],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0]
        ];
    }

    function test_WhitelistPath() public {
        address tokenIn = WETH;
        address tokenOut = SUSDE;
        (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams) = _input();

        assertFalse(curveAdapter.whitelistedPaths(tokenIn, tokenOut, route, swapParams, pools));
        _whitelistPath(tokenIn, tokenOut, route, swapParams, pools);
    }

    function test_BlacklistPath() public {
        address tokenIn = WETH;
        address tokenOut = SUSDE;
        (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams) = _input();
        _whitelistPath(tokenIn, tokenOut, route, swapParams, pools);

        vm.prank(roles.whitelistManager);
        curveAdapter.blacklistPath(tokenIn, tokenOut, route, swapParams, pools);
        assertFalse(curveAdapter.whitelistedPaths(tokenIn, tokenOut, route, swapParams, pools));
    }

    function test_SwapWETHToSUSDEUsingPredefinedPath() public {
        uint256 amountIn = 1 ether;
        deal(WETH, address(this), amountIn);
        (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams) = _input();

        _whitelistPath(WETH, SUSDE, route, swapParams, pools);

        IERC20(WETH).forceApprove(address(curveAdapter), amountIn);

        uint256 balanceBefore = IERC20(SUSDE).balanceOf(address(this));
        curveAdapter.swap(WETH, SUSDE, amountIn, 0, address(this), abi.encode(route, swapParams, pools));
        uint256 balanceAfter = IERC20(SUSDE).balanceOf(address(this));
        assertGt(balanceAfter, balanceBefore);
    }
}
