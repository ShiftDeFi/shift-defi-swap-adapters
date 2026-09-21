// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {UniswapV3SwapRouter02Adapter} from "contracts/UniswapV3SwapRouter02Adapter.sol";
import {IUniswapV3SwapRouter02Adapter} from "contracts/interfaces/IUniswapV3SwapRouter02Adapter.sol";

import {IWMON} from "test/mocks/IWMON.sol";
import {Base} from "test/Base.t.sol";

/// @dev Forks Monad mainnet and swaps against the real, deployed SwapRouter02
/// and the live WMON/USDC pool - see entry-exit/[Predefined Swap] WMON→ USDC
/// Monad.md. Pinned block confirmed (via `cast`) to have an unlocked pool with
/// non-zero liquidity at pool address 0x659bD0BC4167BA25c62E05656F78043E7eD4a9da
/// (fee 3000). Run with `MONAD_RPC_URL` set - not part of `make verify`.
contract WmonUsdcForkTest is Base {
    uint256 internal constant MONAD_FORK_BLOCK = 105_296_000;

    IWMON internal constant WMON = IWMON(0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A);
    IERC20 internal constant USDC = IERC20(0x754704Bc059F8C67012fEd69BC8A327a5aafb603);
    address internal constant UNISWAP_V3_SWAP_ROUTER_02 = 0xfE31F71C1b106EAc32F1A19239c9a9A72ddfb900;

    uint24 internal constant FEE = 3000;
    uint256 internal constant AMOUNT_IN = 1 ether;

    UniswapV3SwapRouter02Adapter internal uniswapV3Adapter;

    function setUp() public virtual override {
        super.setUp();

        vm.createSelectFork(vm.rpcUrl("monad"), MONAD_FORK_BLOCK);

        uniswapV3Adapter = new UniswapV3SwapRouter02Adapter(roles.defaultAdmin, UNISWAP_V3_SWAP_ROUTER_02);
        vm.label(address(uniswapV3Adapter), "UNISWAP_V3_SWAP_ROUTER_02");
        vm.label(address(WMON), "WMON");
        vm.label(address(USDC), "USDC");
        vm.label(UNISWAP_V3_SWAP_ROUTER_02, "SWAP_ROUTER_02");

        vm.prank(roles.defaultAdmin);
        AccessControl(address(uniswapV3Adapter)).grantRole(WHITELIST_MANAGER_ROLE, roles.whitelistManager);
    }

    function test_Swap_WmonToUsdc() public {
        bytes memory path = _whitelistWmonUsdcPath();
        _dealWmon(users.alice, AMOUNT_IN);

        vm.startPrank(users.alice);
        WMON.approve(address(uniswapV3Adapter), AMOUNT_IN);
        uniswapV3Adapter.swap(address(WMON), address(USDC), AMOUNT_IN, 1, users.bob, path);
        vm.stopPrank();

        assertEq(WMON.balanceOf(users.alice), 0, "test_Swap_WmonToUsdc: WMON not pulled from alice");
        assertGt(USDC.balanceOf(users.bob), 0, "test_Swap_WmonToUsdc: no USDC received by receiver");
        assertEq(
            USDC.balanceOf(address(uniswapV3Adapter)),
            0,
            "test_Swap_WmonToUsdc: USDC left stranded in the adapter"
        );
    }

    function test_RevertIf_Swap_PathNotWhitelisted() public {
        bytes memory path = abi.encodePacked(address(WMON), FEE, address(USDC));
        _dealWmon(users.alice, AMOUNT_IN);

        vm.startPrank(users.alice);
        WMON.approve(address(uniswapV3Adapter), AMOUNT_IN);
        vm.expectRevert(abi.encodeWithSelector(IUniswapV3SwapRouter02Adapter.PathNotWhitelisted.selector, path));
        uniswapV3Adapter.swap(address(WMON), address(USDC), AMOUNT_IN, 1, users.bob, path);
        vm.stopPrank();
    }

    /// @dev `minAmountOut` is forwarded to the real router as its own
    /// `amountOutMinimum`, so an unreachable minimum reverts inside the
    /// router itself, before the adapter's own SlippageCheckFailed check ever
    /// runs - hence the generic `vm.expectRevert()`.
    function test_RevertIf_Swap_MinAmountOutNotMet() public {
        bytes memory path = _whitelistWmonUsdcPath();
        _dealWmon(users.alice, AMOUNT_IN);

        uint256 unreachableMinAmountOut = type(uint256).max;

        vm.startPrank(users.alice);
        WMON.approve(address(uniswapV3Adapter), AMOUNT_IN);
        vm.expectRevert();
        uniswapV3Adapter.swap(address(WMON), address(USDC), AMOUNT_IN, unreachableMinAmountOut, users.bob, path);
        vm.stopPrank();
    }

    function _whitelistWmonUsdcPath() internal returns (bytes memory path) {
        address[] memory tokens = new address[](2);
        tokens[0] = address(WMON);
        tokens[1] = address(USDC);

        uint24[] memory fees = new uint24[](1);
        fees[0] = FEE;

        vm.prank(roles.whitelistManager);
        path = uniswapV3Adapter.whitelistPath(tokens, fees);
    }

    /// @dev Wraps native MON into WMON for `account`, exercising the real
    /// WMON contract's deposit() rather than minting a mock balance.
    function _dealWmon(address account, uint256 amount) internal {
        vm.deal(account, amount);
        vm.prank(account);
        WMON.deposit{value: amount}();
    }
}
