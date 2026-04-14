// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PyusdUsdcEthereumAdapter} from "contracts/custom-adapters/ethereum/PyusdUsdcEthereumAdapter.sol";
import {IPyusdUsdcEthereumAdapter} from "contracts/interfaces/IPyusdUsdcEthereumAdapter.sol";
import {ICurveStableSwapNG} from "contracts/dependencies/curve/ICurveStableSwapNG.sol";

import {Base} from "test/Base.t.sol";
import {console2 as console} from "forge-std/console2.sol";

contract PyusdUsdcEthereumAdapterTest is Base {
    using SafeERC20 for IERC20;

    PyusdUsdcEthereumAdapter internal pyusdUsdcEthereumAdapter;

    address internal constant PYUSD = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;

    ICurveStableSwapNG internal constant SPARK_POOL = ICurveStableSwapNG(0xA632D59b9B804a956BfaA9b48Af3A1b74808FC1f);
    ICurveStableSwapNG internal constant PAY_POOL = ICurveStableSwapNG(0x383E6b4437b59fff47B619CBA855CA29342A8559);
    address internal constant USDS_WRAPPER = 0xA188EEC8F81263234dA3622A406892F3D630f98c;

    address internal constant USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;
    address internal constant PYUSD_WHALE = 0x1601843c5E9bC251A3272907010AFa41Fa18347E;

    uint256 internal constant DEFAULT_USDC_AMOUNT_IN = 1_000_000 * 10 ** 6;
    uint256 internal constant DEFAULT_PYUSD_AMOUNT_IN = 1_000_000 * 10 ** 6;

    uint256 internal constant MAX_SLIPPAGE = 0.001e18; // 0.1%

    function setUp() public override {
        super.setUp();

        pyusdUsdcEthereumAdapter = new PyusdUsdcEthereumAdapter();
        vm.label(address(pyusdUsdcEthereumAdapter), "PYUSD_USDC_ETHEREUM_ADAPTER");
    }

    function _lowerSparkQuote() internal {
        uint256 amountIn = 30 * DEFAULT_PYUSD_AMOUNT_IN;
        vm.startPrank(PYUSD_WHALE);
        IERC20(PYUSD).safeIncreaseAllowance(address(SPARK_POOL), amountIn);
        SPARK_POOL.exchange(0, 1, amountIn, 0);
        vm.stopPrank();
    }

    function _lowerPayQuote() internal {
        uint256 amountIn = 30 * DEFAULT_PYUSD_AMOUNT_IN;
        vm.startPrank(PYUSD_WHALE);
        IERC20(PYUSD).safeIncreaseAllowance(address(PAY_POOL), amountIn);
        PAY_POOL.exchange(0, 1, amountIn, 0);
        vm.stopPrank();
    }

    function test_GetSparkQuoteUsdc() public view {
        uint256 amountOut = pyusdUsdcEthereumAdapter.getSparkQuoteUsdc(DEFAULT_PYUSD_AMOUNT_IN);
        assertApproxEqAbs(amountOut, DEFAULT_USDC_AMOUNT_IN, MAX_SLIPPAGE, "test_GetSparkQuoteUsdc slippage");
    }

    function test_GetPayQuoteUsdc() public view {
        uint256 amountOut = pyusdUsdcEthereumAdapter.getPayQuoteUsdc(DEFAULT_PYUSD_AMOUNT_IN);
        assertApproxEqAbs(amountOut, DEFAULT_USDC_AMOUNT_IN, MAX_SLIPPAGE, "test_GetPayQuoteUsdc slippage");
    }

    function test_PreviewSwap() public {
        uint256 sparkQuote = pyusdUsdcEthereumAdapter.getSparkQuoteUsdc(DEFAULT_PYUSD_AMOUNT_IN);
        uint256 payQuote = pyusdUsdcEthereumAdapter.getPayQuoteUsdc(DEFAULT_PYUSD_AMOUNT_IN);

        if (sparkQuote > payQuote) {
            assertEq(pyusdUsdcEthereumAdapter.previewSwap(PYUSD, USDC, DEFAULT_PYUSD_AMOUNT_IN, ""), sparkQuote);

            _lowerSparkQuote();
            assertEq(pyusdUsdcEthereumAdapter.previewSwap(PYUSD, USDC, DEFAULT_PYUSD_AMOUNT_IN, ""), payQuote);
        } else {
            assertEq(pyusdUsdcEthereumAdapter.previewSwap(PYUSD, USDC, DEFAULT_PYUSD_AMOUNT_IN, ""), payQuote);

            _lowerPayQuote();
            assertEq(pyusdUsdcEthereumAdapter.previewSwap(PYUSD, USDC, DEFAULT_PYUSD_AMOUNT_IN, ""), sparkQuote);
        }
    }

    function test_RevertIf_PreviewSwap_InvalidTokenPreview() public {
        vm.expectRevert(abi.encodeWithSelector(IPyusdUsdcEthereumAdapter.InvalidTokenIn.selector, USDC, PYUSD));
        pyusdUsdcEthereumAdapter.previewSwap(USDC, USDC, DEFAULT_PYUSD_AMOUNT_IN, "");

        vm.expectRevert(abi.encodeWithSelector(IPyusdUsdcEthereumAdapter.InvalidTokenOut.selector, PYUSD, USDC));
        pyusdUsdcEthereumAdapter.previewSwap(PYUSD, PYUSD, DEFAULT_PYUSD_AMOUNT_IN, "");
    }

    function test_Swap() public {
        uint256 amountIn = DEFAULT_PYUSD_AMOUNT_IN;
        uint256 minAmountOut = 0;
        address receiver = users.alice;
        bytes memory data = "";

        vm.startPrank(PYUSD_WHALE);
        IERC20(PYUSD).safeIncreaseAllowance(address(pyusdUsdcEthereumAdapter), amountIn);
        pyusdUsdcEthereumAdapter.swap(PYUSD, USDC, amountIn, minAmountOut, receiver, data);
        vm.stopPrank();
    }

    function test_Swap_ForceSparkPool() public {
        uint256 amountIn = DEFAULT_PYUSD_AMOUNT_IN;
        uint256 minAmountOut = 0;
        address receiver = users.alice;
        bytes memory data = "";

        uint256 sparkQuote = pyusdUsdcEthereumAdapter.getSparkQuoteUsdc(amountIn);
        uint256 payQuote = pyusdUsdcEthereumAdapter.getPayQuoteUsdc(amountIn);

        if (sparkQuote > payQuote) {
            _lowerPayQuote();
        }

        assertGt(
            pyusdUsdcEthereumAdapter.getSparkQuoteUsdc(amountIn),
            pyusdUsdcEthereumAdapter.getPayQuoteUsdc(amountIn)
        );

        vm.startPrank(PYUSD_WHALE);
        IERC20(PYUSD).safeIncreaseAllowance(address(pyusdUsdcEthereumAdapter), amountIn);
        pyusdUsdcEthereumAdapter.swap(PYUSD, USDC, amountIn, minAmountOut, receiver, data);
        vm.stopPrank();

        assertApproxEqAbs(IERC20(USDC).balanceOf(receiver), amountIn, MAX_SLIPPAGE);
    }

    function test_Swap_ForcePayPool() public {
        uint256 amountIn = DEFAULT_PYUSD_AMOUNT_IN;
        uint256 minAmountOut = 0;
        address receiver = users.alice;
        bytes memory data = "";

        uint256 sparkQuote = pyusdUsdcEthereumAdapter.getSparkQuoteUsdc(amountIn);
        uint256 payQuote = pyusdUsdcEthereumAdapter.getPayQuoteUsdc(amountIn);

        if (sparkQuote > payQuote) {
            _lowerSparkQuote();
        }

        assertGt(
            pyusdUsdcEthereumAdapter.getPayQuoteUsdc(amountIn),
            pyusdUsdcEthereumAdapter.getSparkQuoteUsdc(amountIn)
        );

        vm.startPrank(PYUSD_WHALE);
        IERC20(PYUSD).safeIncreaseAllowance(address(pyusdUsdcEthereumAdapter), amountIn);
        pyusdUsdcEthereumAdapter.swap(PYUSD, USDC, amountIn, minAmountOut, receiver, data);
        vm.stopPrank();

        assertApproxEqAbs(IERC20(USDC).balanceOf(receiver), amountIn, MAX_SLIPPAGE);
    }

    function test_RevertIf_Swap_InvalidTokenSwap() public {
        vm.expectRevert(abi.encodeWithSelector(IPyusdUsdcEthereumAdapter.InvalidTokenIn.selector, USDC, PYUSD));
        pyusdUsdcEthereumAdapter.swap(USDC, USDC, DEFAULT_PYUSD_AMOUNT_IN, 0, users.alice, "");

        vm.expectRevert(abi.encodeWithSelector(IPyusdUsdcEthereumAdapter.InvalidTokenOut.selector, PYUSD, USDC));
        pyusdUsdcEthereumAdapter.swap(PYUSD, PYUSD, DEFAULT_PYUSD_AMOUNT_IN, 0, users.alice, "");
    }
}
