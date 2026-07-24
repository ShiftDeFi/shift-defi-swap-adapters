// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IPyusdUsdcEthereumAdapter, ISwapAdapter} from "contracts/interfaces/IPyusdUsdcEthereumAdapter.sol";

import {ICurveStableSwapNG} from "contracts/dependencies/curve/ICurveStableSwapNG.sol";
import {ILitePsmWrapper} from "contracts/dependencies/spark/ILitePsmWrapper.sol";

contract PyusdUsdcEthereumAdapter is IPyusdUsdcEthereumAdapter {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant PYUSD = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;
    address private constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;

    ICurveStableSwapNG private constant SPARK_POOL = ICurveStableSwapNG(0xA632D59b9B804a956BfaA9b48Af3A1b74808FC1f);
    ICurveStableSwapNG private constant PAY_POOL = ICurveStableSwapNG(0x383E6b4437b59fff47B619CBA855CA29342A8559);
    address private constant USDS_WRAPPER = 0xA188EEC8F81263234dA3622A406892F3D630f98c;

    int128 private constant PYUSD_INDEX = 0;
    int128 private constant USDC_INDEX = 1;
    int128 private constant USDS_INDEX = 1;
    uint256 private constant USDS_TO_USDC_SCALE = 10 ** 12;
    uint256 private constant WAD = 1e18;

    /// @inheritdoc ISwapAdapter
    function previewSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bytes memory
    ) external view override returns (uint256) {
        require(tokenIn == PYUSD, InvalidTokenIn(tokenIn, PYUSD));
        require(tokenOut == USDC, InvalidTokenOut(tokenOut, USDC));

        uint256 sparkQuote = getSparkQuoteUsdc(amountIn);
        uint256 payQuote = getPayQuoteUsdc(amountIn);

        if (sparkQuote > payQuote) {
            return sparkQuote;
        } else {
            return payQuote;
        }
    }

    /// @inheritdoc ISwapAdapter
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bytes memory
    ) external payable override {
        require(tokenIn == PYUSD, InvalidTokenIn(tokenIn, PYUSD));
        require(tokenOut == USDC, InvalidTokenOut(tokenOut, USDC));

        uint256 sparkQuote = getSparkQuoteUsdc(amountIn);
        uint256 payQuote = getPayQuoteUsdc(amountIn);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        if (sparkQuote > payQuote) {
            IERC20(PYUSD).safeIncreaseAllowance(address(SPARK_POOL), amountIn);
            uint256 amountOutUsds = SPARK_POOL.exchange(PYUSD_INDEX, USDS_INDEX, amountIn, minAmountOut);

            IERC20(USDS).safeIncreaseAllowance(address(USDS_WRAPPER), amountOutUsds);
            ILitePsmWrapper(USDS_WRAPPER).buyGem(receiver, sparkQuote);
        } else {
            IERC20(PYUSD).safeIncreaseAllowance(address(PAY_POOL), amountIn);
            uint256 amountOutUsdc = PAY_POOL.exchange(PYUSD_INDEX, USDC_INDEX, amountIn, minAmountOut);
            IERC20(USDC).safeTransfer(receiver, amountOutUsdc);
        }
    }

    function getSparkQuoteUsdc(uint256 amountIn) public view returns (uint256 amountOut) {
        uint256 amountOutUsds = SPARK_POOL.get_dy(PYUSD_INDEX, USDS_INDEX, amountIn);
        uint256 tout = ILitePsmWrapper(USDS_WRAPPER).tout();
        return amountOutUsds.mulDiv(WAD, USDS_TO_USDC_SCALE * (tout + WAD));
    }

    function getPayQuoteUsdc(uint256 amountIn) public view returns (uint256 amountOut) {
        return PAY_POOL.get_dy(PYUSD_INDEX, USDC_INDEX, amountIn);
    }
}
