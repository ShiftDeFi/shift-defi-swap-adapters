// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";

import {IUniswapV3SwapRouter02Adapter} from "contracts/interfaces/IUniswapV3SwapRouter02Adapter.sol";

import {UniswapV3SwapRouter02AdapterBase} from "test/unit/UniswapV3SwapRouter02Adapter/UniswapV3SwapRouter02AdapterBase.t.sol";

contract UniswapV3SwapRouter02AdapterSwapTest is UniswapV3SwapRouter02AdapterBase {
    uint256 internal constant AMOUNT_IN = 1 ether;

    function test_Swap() public {
        bytes memory path = _whitelistPath();
        _fundAndApprove(users.alice, AMOUNT_IN);

        vm.prank(users.alice);
        ISwapAdapter(address(uniswapV3Adapter)).swap(
            address(tokenA),
            address(tokenB),
            AMOUNT_IN,
            AMOUNT_IN,
            users.bob,
            path
        );

        assertEq(tokenA.balanceOf(users.alice), 0, "test_Swap: tokenA not pulled from alice");
        assertEq(tokenB.balanceOf(users.bob), AMOUNT_IN, "test_Swap: tokenB not received by receiver");
        assertEq(tokenA.balanceOf(address(uniswapV3Adapter)), 0, "test_Swap: tokenA left in the adapter");
        assertEq(tokenB.balanceOf(address(uniswapV3Adapter)), 0, "test_Swap: tokenB left in the adapter");
        assertEq(
            tokenA.allowance(address(uniswapV3Adapter), address(swapRouter02Mock)),
            0,
            "test_Swap: router allowance not reset"
        );
    }

    function test_RevertIf_Swap_PartialFill() public {
        bytes memory path = _whitelistPath();
        _fundAndApprove(users.alice, AMOUNT_IN);

        uint256 fillAmount = AMOUNT_IN / 2;
        swapRouter02Mock.setFillAmount(fillAmount);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(IUniswapV3SwapRouter02Adapter.PartialFill.selector, AMOUNT_IN, fillAmount)
        );
        ISwapAdapter(address(uniswapV3Adapter)).swap(address(tokenA), address(tokenB), AMOUNT_IN, 1, users.bob, path);
    }

    function test_RevertIf_Swap_TokenInPathMismatch() public {
        bytes memory path = _whitelistPath();
        ERC20Mock worthless = new ERC20Mock();
        worthless.mint(users.alice, AMOUNT_IN);

        vm.startPrank(users.alice);
        worthless.approve(address(uniswapV3Adapter), AMOUNT_IN);
        vm.expectRevert(
            abi.encodeWithSelector(
                IUniswapV3SwapRouter02Adapter.TokenInPathMismatch.selector,
                address(worthless),
                address(tokenA)
            )
        );
        ISwapAdapter(address(uniswapV3Adapter)).swap(
            address(worthless),
            address(tokenB),
            AMOUNT_IN,
            0,
            users.alice,
            path
        );
        vm.stopPrank();
    }

    function test_RevertIf_Swap_TokenOutPathMismatch() public {
        bytes memory path = _whitelistPath();
        _fundAndApprove(users.alice, AMOUNT_IN);
        address wrongTokenOut = makeAddr("WRONG_TOKEN_OUT");

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IUniswapV3SwapRouter02Adapter.TokenOutPathMismatch.selector,
                wrongTokenOut,
                address(tokenB)
            )
        );
        ISwapAdapter(address(uniswapV3Adapter)).swap(address(tokenA), wrongTokenOut, AMOUNT_IN, 0, users.bob, path);
    }

    function test_RevertIf_Swap_PathNotWhitelisted() public {
        bytes memory path = abi.encodePacked(address(tokenA), FEE, address(tokenB));
        _fundAndApprove(users.alice, AMOUNT_IN);

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(IUniswapV3SwapRouter02Adapter.PathNotWhitelisted.selector, path));
        ISwapAdapter(address(uniswapV3Adapter)).swap(address(tokenA), address(tokenB), AMOUNT_IN, 0, users.bob, path);
    }

    /// @dev The audited griefing case: the harvest swaps a 1 wei WMON balance
    /// while 1 wei of native sits on SwapRouter02. Without the refund the router
    /// pays from its own balance and the adapter reverts with PartialFill.
    function test_Swap_Weth9_RouterHoldsNativeDust() public {
        _assertWeth9SwapPullsAdapterTokens(1, 1);
    }

    function test_Swap_Weth9_RouterHoldsNativeCoveringAmountIn() public {
        _assertWeth9SwapPullsAdapterTokens(AMOUNT_IN, AMOUNT_IN);
    }

    function test_Swap_NonWeth9_RouterNativeBalanceUntouched() public {
        bytes memory path = _whitelistPath();
        _fundAndApprove(users.alice, AMOUNT_IN);
        vm.deal(address(swapRouter02Mock), AMOUNT_IN);

        vm.prank(users.alice);
        ISwapAdapter(address(uniswapV3Adapter)).swap(
            address(tokenA),
            address(tokenB),
            AMOUNT_IN,
            AMOUNT_IN,
            users.bob,
            path
        );

        assertEq(
            address(swapRouter02Mock).balance,
            AMOUNT_IN,
            "test_Swap_NonWeth9_RouterNativeBalanceUntouched: router native balance swept"
        );
        assertEq(
            tokenB.balanceOf(users.bob),
            AMOUNT_IN,
            "test_Swap_NonWeth9_RouterNativeBalanceUntouched: wrong amount out"
        );
    }

    function test_RevertIf_Receive_NotSwapRouter02() public {
        vm.deal(users.alice, 1);

        vm.prank(users.alice);
        vm.expectRevert(
            abi.encodeWithSelector(IUniswapV3SwapRouter02Adapter.UnexpectedNativeSender.selector, users.alice)
        );
        (bool success, ) = address(uniswapV3Adapter).call{value: 1}("");
        success;
    }

    function _assertWeth9SwapPullsAdapterTokens(uint256 amountIn, uint256 routerNative) internal {
        bytes memory path = _whitelistPath(address(weth9), address(tokenB));
        weth9.mint(users.alice, amountIn);
        vm.prank(users.alice);
        weth9.approve(address(uniswapV3Adapter), amountIn);
        vm.deal(address(swapRouter02Mock), routerNative);

        vm.prank(users.alice);
        ISwapAdapter(address(uniswapV3Adapter)).swap(
            address(weth9),
            address(tokenB),
            amountIn,
            amountIn,
            users.bob,
            path
        );

        assertEq(weth9.balanceOf(users.alice), 0, "_assertWeth9SwapPullsAdapterTokens: WETH9 not pulled from alice");
        assertEq(
            tokenB.balanceOf(users.bob),
            amountIn + routerNative,
            "_assertWeth9SwapPullsAdapterTokens: refunded native not swapped for the receiver"
        );
        assertEq(address(swapRouter02Mock).balance, 0, "_assertWeth9SwapPullsAdapterTokens: router native not swept");
        assertEq(
            address(uniswapV3Adapter).balance,
            0,
            "_assertWeth9SwapPullsAdapterTokens: native left in the adapter"
        );
        assertEq(
            weth9.balanceOf(address(uniswapV3Adapter)),
            0,
            "_assertWeth9SwapPullsAdapterTokens: WETH9 left in the adapter"
        );
        assertEq(
            weth9.allowance(address(uniswapV3Adapter), address(swapRouter02Mock)),
            0,
            "_assertWeth9SwapPullsAdapterTokens: router allowance not reset"
        );
    }

    function _fundAndApprove(address account, uint256 amount) internal {
        tokenA.mint(account, amount);
        vm.prank(account);
        tokenA.approve(address(uniswapV3Adapter), amount);
    }
}
