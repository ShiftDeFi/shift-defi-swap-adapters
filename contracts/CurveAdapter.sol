// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";
import {ICurveRouter} from "./dependencies/curve/ICurveRouter.sol";
import {ICurveAdapter} from "./interfaces/ICurveAdapter.sol";

contract CurveAdapter is AccessControl, ReentrancyGuard, ISwapAdapter, ICurveAdapter {
    using SafeERC20 for IERC20;

    address public curveRouter;
    mapping(bytes32 => bool) private _whitelistedPaths;

    bytes32 private constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");

    constructor(address _defaultAdmin, address _curveRouter, address _whitelistManager) {
        if (_defaultAdmin == address(0)) revert ZeroAddress();
        if (_curveRouter == address(0)) revert ZeroAddress();
        if (_whitelistManager == address(0)) revert ZeroAddress();
        curveRouter = _curveRouter;
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(WHITELIST_MANAGER_ROLE, _whitelistManager);
    }

    /// @inheritdoc ICurveAdapter
    function whitelistPath(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) external onlyRole(WHITELIST_MANAGER_ROLE) {
        bytes32 pathKey = _computeKey(tokenIn, tokenOut, route, swapParams, pools);
        if (_whitelistedPaths[pathKey]) revert PathAlreadyWhitelisted(pathKey);
        _whitelistedPaths[pathKey] = true;
        emit PathWhitelisted(tokenIn, tokenOut);
    }

    /// @inheritdoc ICurveAdapter
    function blacklistPath(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) external onlyRole(WHITELIST_MANAGER_ROLE) {
        bytes32 pathKey = _computeKey(tokenIn, tokenOut, route, swapParams, pools);
        if (!_whitelistedPaths[pathKey]) revert PathNotWhitelisted(pathKey);
        _whitelistedPaths[pathKey] = false;
        emit PathBlacklisted(tokenIn, tokenOut);
    }

    /// @inheritdoc ISwapAdapter
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        bytes calldata data
    ) external payable override nonReentrant {
        if (amountIn == 0) revert ZeroAmount();
        SwapLocalVariables memory vars;

        (vars.route, vars.swapParams, vars.pools) = abi.decode(data, (address[11], uint256[5][5], address[5]));
        vars.pathKey = _computeKey(tokenIn, tokenOut, vars.route, vars.swapParams, vars.pools);
        require(_whitelistedPaths[vars.pathKey], PathNotWhitelisted(vars.pathKey));

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(curveRouter, amountIn);

        vars.balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        ICurveRouter(curveRouter).exchange(vars.route, vars.swapParams, amountIn, minAmountOut, vars.pools);
        vars.deltaTokenOut = IERC20(tokenOut).balanceOf(address(this)) - vars.balanceBefore;
        require(vars.deltaTokenOut >= minAmountOut, SlippageNotMet(tokenOut, vars.deltaTokenOut, minAmountOut));

        IERC20(tokenOut).safeTransfer(receiver, vars.deltaTokenOut);
    }

    /// @inheritdoc ICurveAdapter
    function whitelistedPaths(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) external view returns (bool) {
        return _whitelistedPaths[_computeKey(tokenIn, tokenOut, route, swapParams, pools)];
    }

    function _computeKey(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) private pure returns (bytes32 key) {
        bytes memory data = abi.encode(tokenIn, tokenOut, route, swapParams, pools);
        assembly {
            key := keccak256(add(data, 0x20), mload(data))
        }
    }
}
