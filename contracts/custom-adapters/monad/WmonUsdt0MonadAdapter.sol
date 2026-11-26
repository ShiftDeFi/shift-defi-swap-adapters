// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";

import {IWmonUsdt0MonadAdapter} from "../../interfaces/IWmonUsdt0MonadAdapter.sol";
import {IWETH9} from "../../dependencies/IWETH9.sol";
import {ISwapRouter02} from "../../dependencies/uniswap-v3/ISwapRouter02.sol";
import {ICurveStableSwapNG} from "../../dependencies/curve/ICurveStableSwapNG.sol";

contract WmonUsdt0MonadAdapter is ReentrancyGuard, IWmonUsdt0MonadAdapter {
    using SafeERC20 for IERC20;

    address private constant WMON = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;
    address private constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
    address private constant USDT0 = 0xe7cd86e13AC4309349F30B3435a9d337750fC82D;

    ISwapRouter02 private constant SWAP_ROUTER_02 = ISwapRouter02(0xfE31F71C1b106EAc32F1A19239c9a9A72ddfb900);
    ICurveStableSwapNG private constant CURVE_3POOL = ICurveStableSwapNG(0x942644106B073E30D72c2C5D7529D5C296ea91ab);

    uint24 private constant UNISWAP_FEE = 3000;
    int128 private constant USDC_INDEX = 1;
    int128 private constant USDT0_INDEX = 2;

    /// @dev Only SwapRouter02's `refundETH` sends native tokens here (see `swap`).
    receive() external payable {
        require(msg.sender == address(SWAP_ROUTER_02), UnexpectedNativeSender(msg.sender));
    }

    /// @inheritdoc ISwapAdapter
    function previewSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bytes memory data
    ) external view override returns (uint256 amountOut) {}

    /// @inheritdoc ISwapAdapter
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bytes memory
    ) external payable override nonReentrant {
        require(tokenIn == WMON, InvalidTokenIn(tokenIn, WMON));
        require(tokenOut == USDT0, InvalidTokenOut(tokenOut, USDT0));

        IERC20(WMON).safeTransferFrom(msg.sender, address(this), amountIn);
        amountIn += _wrapRouterNative();

        uint256 amountUsdc = _swapWmonToUsdc(amountIn);
        // Dust WMON buys zero USDC, and the Curve pool reverts on a zero `dx`.
        uint256 amountUsdt0 = amountUsdc == 0 ? 0 : _swapUsdcToUsdt0(amountUsdc, minAmountOut);

        require(amountUsdt0 >= minAmountOut, SlippageCheckFailed(USDT0, amountUsdt0, minAmountOut));
        IERC20(USDT0).safeTransfer(receiver, amountUsdt0);
    }

    function _wrapRouterNative() private returns (uint256 refunded) {
        uint256 nativeBalanceBefore = address(this).balance;
        SWAP_ROUTER_02.refundETH();
        refunded = address(this).balance - nativeBalanceBefore;
        if (refunded > 0) {
            IWETH9(WMON).deposit{value: refunded}();
        }
    }

    function _swapWmonToUsdc(uint256 amountIn) private returns (uint256) {
        uint256 wmonBalanceBefore = IERC20(WMON).balanceOf(address(this));
        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(address(this));

        IERC20(WMON).forceApprove(address(SWAP_ROUTER_02), amountIn);
        SWAP_ROUTER_02.exactInput(
            ISwapRouter02.ExactInputParams({
                path: abi.encodePacked(WMON, UNISWAP_FEE, USDC),
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0
            })
        );
        IERC20(WMON).forceApprove(address(SWAP_ROUTER_02), 0);

        uint256 amountInSpent = wmonBalanceBefore - IERC20(WMON).balanceOf(address(this));
        require(amountInSpent == amountIn, PartialFill(amountIn, amountInSpent));

        return IERC20(USDC).balanceOf(address(this)) - usdcBalanceBefore;
    }

    function _swapUsdcToUsdt0(uint256 amountUsdc, uint256 minAmountOut) private returns (uint256) {
        uint256 usdt0BalanceBefore = IERC20(USDT0).balanceOf(address(this));

        IERC20(USDC).forceApprove(address(CURVE_3POOL), amountUsdc);
        CURVE_3POOL.exchange(USDC_INDEX, USDT0_INDEX, amountUsdc, minAmountOut);
        IERC20(USDC).forceApprove(address(CURVE_3POOL), 0);

        return IERC20(USDT0).balanceOf(address(this)) - usdt0BalanceBefore;
    }
}
