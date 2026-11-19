// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {SwapRouter} from "@shift-defi/core/SwapRouter.sol";
import {ISwapRouter} from "@shift-defi/core/interfaces/ISwapRouter.sol";

import {WmonUsdt0MonadAdapter} from "contracts/custom-adapters/monad/WmonUsdt0MonadAdapter.sol";
import {IWmonUsdt0MonadAdapter} from "contracts/interfaces/IWmonUsdt0MonadAdapter.sol";

import {IWMON} from "test/dependencies/IWMON.sol";
import {Base} from "test/Base.t.sol";

contract WmonUsdt0MonadAdapterForkTest is Base {
    uint256 internal constant MONAD_FORK_BLOCK = 105_296_000;

    IWMON internal constant WMON = IWMON(0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A);
    IERC20 internal constant USDC = IERC20(0x754704Bc059F8C67012fEd69BC8A327a5aafb603);
    IERC20 internal constant USDT0 = IERC20(0xe7cd86e13AC4309349F30B3435a9d337750fC82D);
    address internal constant UNISWAP_V3_SWAP_ROUTER_02 = 0xfE31F71C1b106EAc32F1A19239c9a9A72ddfb900;
    address internal constant CURVE_3POOL = 0x942644106B073E30D72c2C5D7529D5C296ea91ab;

    uint256 internal constant AMOUNT_IN = 1 ether;

    WmonUsdt0MonadAdapter internal adapter;

    function setUp() public virtual override {
        super.setUp();

        vm.createSelectFork(vm.rpcUrl("monad"), MONAD_FORK_BLOCK);

        adapter = new WmonUsdt0MonadAdapter();
        vm.label(address(adapter), "WMON_USDT0_MONAD_ADAPTER");
        vm.label(address(WMON), "WMON");
        vm.label(address(USDC), "USDC");
        vm.label(address(USDT0), "USDT0");
        vm.label(UNISWAP_V3_SWAP_ROUTER_02, "SWAP_ROUTER_02");
        vm.label(CURVE_3POOL, "CURVE_3POOL");
    }

    function test_Swap_WmonToUsdt0() public {
        _dealWmon(users.alice, AMOUNT_IN);

        vm.startPrank(users.alice);
        WMON.approve(address(adapter), AMOUNT_IN);
        adapter.swap(address(WMON), address(USDT0), AMOUNT_IN, 1, users.bob, "");
        vm.stopPrank();

        assertEq(WMON.balanceOf(users.alice), 0, "test_Swap_WmonToUsdt0: WMON not pulled from alice");
        assertGt(USDT0.balanceOf(users.bob), 0, "test_Swap_WmonToUsdt0: no USDT0 received by receiver");
        _assertAdapterClean("test_Swap_WmonToUsdt0");
    }

    function test_Swap_WmonToUsdt0_RouterHoldsNative() public {
        _dealWmon(users.alice, AMOUNT_IN);
        vm.deal(UNISWAP_V3_SWAP_ROUTER_02, AMOUNT_IN);

        vm.startPrank(users.alice);
        WMON.approve(address(adapter), AMOUNT_IN);
        adapter.swap(address(WMON), address(USDT0), AMOUNT_IN, 1, users.bob, "");
        vm.stopPrank();

        assertEq(WMON.balanceOf(users.alice), 0, "test_Swap_WmonToUsdt0_RouterHoldsNative: WMON not pulled from alice");
        assertGt(
            USDT0.balanceOf(users.bob), 0, "test_Swap_WmonToUsdt0_RouterHoldsNative: no USDT0 received by receiver"
        );
        assertEq(UNISWAP_V3_SWAP_ROUTER_02.balance, 0, "test_Swap_WmonToUsdt0_RouterHoldsNative: router MON not swept");
        _assertAdapterClean("test_Swap_WmonToUsdt0_RouterHoldsNative");
    }

    function test_Swap_ViaShiftSwapRouter_Predefined() public {
        address shiftSwapRouter = _deployShiftSwapRouter();
        vm.label(shiftSwapRouter, "SHIFT_SWAP_ROUTER");

        vm.startPrank(roles.whitelistManager);
        ISwapRouter(shiftSwapRouter).whitelistSwapAdapter(address(adapter));
        ISwapRouter(shiftSwapRouter).setPredefinedSwapParameters(address(WMON), address(USDT0), address(adapter), "");
        vm.stopPrank();

        _dealWmon(users.alice, AMOUNT_IN);

        vm.startPrank(users.alice);
        WMON.approve(shiftSwapRouter, AMOUNT_IN);
        (bool swapped, uint256 amountOut) =
            ISwapRouter(shiftSwapRouter).tryPredefinedSwap(address(WMON), address(USDT0), AMOUNT_IN, 1);
        vm.stopPrank();

        assertTrue(swapped, "test_Swap_ViaShiftSwapRouter_Predefined: predefined swap not executed");
        assertGt(amountOut, 0, "test_Swap_ViaShiftSwapRouter_Predefined: zero amount out");
        assertEq(
            USDT0.balanceOf(users.alice),
            amountOut,
            "test_Swap_ViaShiftSwapRouter_Predefined: USDT0 not received by caller"
        );
        _assertAdapterClean("test_Swap_ViaShiftSwapRouter_Predefined");
    }

    function test_PreviewSwap_ReturnsZero() public view {
        assertEq(
            adapter.previewSwap(address(WMON), address(USDT0), AMOUNT_IN, ""),
            0,
            "test_PreviewSwap_ReturnsZero: non-zero preview"
        );
    }

    function test_RevertIf_Swap_InvalidTokenIn() public {
        vm.expectRevert(
            abi.encodeWithSelector(IWmonUsdt0MonadAdapter.InvalidTokenIn.selector, address(USDC), address(WMON))
        );
        adapter.swap(address(USDC), address(USDT0), AMOUNT_IN, 1, users.bob, "");
    }

    function test_RevertIf_Swap_InvalidTokenOut() public {
        vm.expectRevert(
            abi.encodeWithSelector(IWmonUsdt0MonadAdapter.InvalidTokenOut.selector, address(USDC), address(USDT0))
        );
        adapter.swap(address(WMON), address(USDC), AMOUNT_IN, 1, users.bob, "");
    }

    function test_RevertIf_Swap_MinAmountOutNotMet() public {
        _dealWmon(users.alice, AMOUNT_IN);

        vm.startPrank(users.alice);
        WMON.approve(address(adapter), AMOUNT_IN);
        vm.expectRevert(bytes("Exchange resulted in fewer coins than expected"));
        adapter.swap(address(WMON), address(USDT0), AMOUNT_IN, type(uint256).max, users.bob, "");
        vm.stopPrank();
    }

    function test_RevertIf_Receive_NotSwapRouter02() public {
        vm.deal(users.alice, 1);

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(IWmonUsdt0MonadAdapter.UnexpectedNativeSender.selector, users.alice));
        (bool success,) = address(adapter).call{value: 1}("");
        success;
    }

    function _assertAdapterClean(string memory testName) internal view {
        assertEq(WMON.balanceOf(address(adapter)), 0, string.concat(testName, ": WMON left in the adapter"));
        assertEq(USDC.balanceOf(address(adapter)), 0, string.concat(testName, ": USDC left in the adapter"));
        assertEq(USDT0.balanceOf(address(adapter)), 0, string.concat(testName, ": USDT0 left in the adapter"));
        assertEq(
            WMON.allowance(address(adapter), UNISWAP_V3_SWAP_ROUTER_02),
            0,
            string.concat(testName, ": router allowance not reset")
        );
        assertEq(
            USDC.allowance(address(adapter), CURVE_3POOL), 0, string.concat(testName, ": curve allowance not reset")
        );
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

    function _dealWmon(address account, uint256 amount) internal {
        vm.deal(account, amount);
        vm.prank(account);
        WMON.deposit{value: amount}();
    }
}
