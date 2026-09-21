// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";
import {ISwapRouter02} from "./dependencies/uniswap-v3/ISwapRouter02.sol";
import {IUniswapV3SwapRouter02Adapter} from "./interfaces/IUniswapV3SwapRouter02Adapter.sol";

/// @dev Targets Uniswap's SwapRouter02 ABI (`ISwapRouter02`), whose
/// `ExactInputParams` carries no `deadline` field - the shape actually
/// deployed on every venue this adapter targets. All swaps go through `swap`;
/// this adapter does not expose `exactInput`/`exactInputSingle` itself.
contract UniswapV3SwapRouter02Adapter is AccessControl, ReentrancyGuard, ISwapAdapter, IUniswapV3SwapRouter02Adapter {
    using SafeERC20 for IERC20;

    bytes32 private constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");

    address public immutable swapRouter02;
    mapping(bytes => bool) public whitelistedPaths;

    /// @dev Grants `DEFAULT_ADMIN_ROLE` to `defaultAdmin` and
    /// `WHITELIST_MANAGER_ROLE` to `whitelistManager`.
    /// @param defaultAdmin Account that receives `DEFAULT_ADMIN_ROLE`.
    /// @param whitelistManager Account that receives `WHITELIST_MANAGER_ROLE`.
    /// @param _swapRouter02 Uniswap SwapRouter02 this adapter calls.
    constructor(address defaultAdmin, address whitelistManager, address _swapRouter02) {
        require(defaultAdmin != address(0), ZeroAddress());
        require(whitelistManager != address(0), ZeroAddress());
        require(_swapRouter02 != address(0), ZeroAddress());
        swapRouter02 = _swapRouter02;
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(WHITELIST_MANAGER_ROLE, whitelistManager);
    }

    modifier onlyWhitelistManager() {
        require(hasRole(WHITELIST_MANAGER_ROLE, msg.sender), NotWhitelistManager(msg.sender));
        _;
    }

    /// @inheritdoc IUniswapV3SwapRouter02Adapter
    function whitelistPath(address[] memory tokens, uint24[] memory fees)
        external
        onlyWhitelistManager
        returns (bytes memory)
    {
        require(tokens.length == fees.length + 1, InvalidPathLengths(tokens.length, fees.length));
        require(fees.length > 0, ZeroHopPath());

        bytes memory path;
        assembly {
            path := mload(0x40)
            let ptr := add(path, 0x20)
            mstore(ptr, shl(96, mload(add(tokens, 0x20))))
            ptr := add(ptr, 20)
            for {
                let i := 0
            } lt(i, mload(fees)) {
                i := add(i, 1)
            } {
                let fee := mload(add(fees, mul(add(i, 1), 0x20)))
                mstore8(ptr, shr(16, and(fee, 0xffffff)))
                mstore8(add(ptr, 1), shr(8, and(fee, 0xffffff)))
                mstore8(add(ptr, 2), and(fee, 0xff))
                ptr := add(ptr, 3)
                mstore(ptr, shl(96, mload(add(tokens, mul(add(i, 2), 0x20)))))
                ptr := add(ptr, 20)
            }
            mstore(path, sub(ptr, add(path, 0x20)))
            mstore(0x40, ptr)
        }

        whitelistedPaths[path] = true;
        emit PathWhitelisted(tokens[0], tokens[tokens.length - 1], path);

        return path;
    }

    /// @inheritdoc IUniswapV3SwapRouter02Adapter
    function decodePath(bytes memory path) public pure returns (address[] memory tokens, uint24[] memory fees) {
        assembly {
            let len := mload(path)
            let n := div(sub(len, 20), 23)

            tokens := mload(0x40)
            mstore(tokens, add(n, 1))
            let feesPtr := add(tokens, add(0x20, mul(add(n, 1), 0x20)))
            fees := feesPtr
            mstore(fees, n)

            let ptr := add(path, 0x20)
            let tokensPtr := add(tokens, 0x20)

            mstore(tokensPtr, shr(96, mload(ptr)))
            ptr := add(ptr, 20)

            for {
                let i := 0
            } lt(i, n) {
                i := add(i, 1)
            } {
                let feeVal := and(shr(232, mload(ptr)), 0xffffff)
                mstore(add(fees, mul(add(i, 1), 0x20)), feeVal)

                ptr := add(ptr, 3)

                tokensPtr := add(tokensPtr, 0x20)
                mstore(tokensPtr, shr(96, mload(ptr)))
                ptr := add(ptr, 20)
            }

            mstore(0x40, and(add(feesPtr, add(0x20, mul(n, 0x20))), not(31)))
        }
    }

    /// @inheritdoc IUniswapV3SwapRouter02Adapter
    function blacklistPath(bytes calldata path) external onlyWhitelistManager {
        require(whitelistedPaths[path], PathNotWhitelisted(path));
        whitelistedPaths[path] = false;

        (address[] memory tokens,) = decodePath(path);
        emit PathBlacklisted(tokens[0], tokens[tokens.length - 1], path);
    }

    /// @inheritdoc ISwapAdapter
    function previewSwap(address tokenIn, address tokenOut, uint256 amountIn, bytes memory data)
        external
        view
        override
        returns (uint256 amountOut)
    {}

    /// @inheritdoc ISwapAdapter
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bytes calldata data
    ) external payable override nonReentrant {
        require(whitelistedPaths[data], PathNotWhitelisted(data));

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).forceApprove(swapRouter02, amountIn);

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        ISwapRouter02(swapRouter02)
            .exactInput(
                ISwapRouter02.ExactInputParams({
                    amountIn: amountIn, amountOutMinimum: minAmountOut, path: data, recipient: address(this)
                })
            );
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));
        uint256 deltaTokenOut = balanceAfter - balanceBefore;
        require(deltaTokenOut >= minAmountOut, SlippageCheckFailed(tokenOut, deltaTokenOut, minAmountOut));
        IERC20(tokenOut).safeTransfer(receiver, deltaTokenOut);
    }
}
