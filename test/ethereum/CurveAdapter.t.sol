// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CurveAdapter} from "contracts/CurveAdapter.sol";
import {ICurveAdapter} from "contracts/interfaces/ICurveAdapter.sol";
import {CurveAdapterBaseTest} from "test/ethereum/CurveAdapterBase.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveAdapterTest is CurveAdapterBaseTest {
    using SafeERC20 for IERC20;

    function test_WhitelistPath() public {
        address tokenIn = WETH;
        address tokenOut = SUSDE;
        (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams) = _input();

        assertFalse(curveAdapter.whitelistedPaths(tokenIn, tokenOut, route, swapParams, pools));
        _whitelistPath(tokenIn, tokenOut, route, swapParams, pools);
        assertTrue(curveAdapter.whitelistedPaths(tokenIn, tokenOut, route, swapParams, pools));
    }

    function test_RevertsIf_WhitelistPathAlreadyWhitelisted() public {
        address tokenIn = WETH;
        address tokenOut = SUSDE;
        (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams) = _input();

        _whitelistPath(tokenIn, tokenOut, route, swapParams, pools);
        assertTrue(curveAdapter.whitelistedPaths(tokenIn, tokenOut, route, swapParams, pools));

        vm.expectRevert(
            abi.encodeWithSelector(
                ICurveAdapter.PathAlreadyWhitelisted.selector,
                _computeKey(tokenIn, tokenOut, route, swapParams, pools)
            )
        );
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

    function test_RevertsIf_BlacklistPathNotWhitelisted() public {
        address tokenIn = WETH;
        address tokenOut = SUSDE;
        (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams) = _input();
        vm.expectRevert(
            abi.encodeWithSelector(
                ICurveAdapter.PathNotWhitelisted.selector,
                _computeKey(tokenIn, tokenOut, route, swapParams, pools)
            )
        );
        vm.prank(roles.whitelistManager);
        curveAdapter.blacklistPath(tokenIn, tokenOut, route, swapParams, pools);
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
