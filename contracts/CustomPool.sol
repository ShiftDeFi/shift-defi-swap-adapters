// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapAdapter} from "@shift-defi/core/interfaces/ISwapAdapter.sol";
import {ICustomPool} from "./interfaces/ICustomPool.sol";

contract CustomPool is AccessControl, ReentrancyGuard, ISwapAdapter, ICustomPool {
    using SafeERC20 for IERC20;

    bytes32 private constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    mapping(address => mapping(address => Price)) public price;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc ICustomPool
    function setPrice(
        address tokenIn,
        address tokenOut,
        uint256 numerator,
        uint256 denominator
    ) external onlyRole(TOKEN_MANAGER_ROLE) {
        require(denominator > 0, InvalidDenominator());
        price[tokenIn][tokenOut] = Price(numerator, denominator);
        emit SetPrice(tokenIn, tokenOut, numerator, denominator);
    }

    /// @inheritdoc ISwapAdapter
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256,
        address receiver,
        bytes calldata
    ) external payable override nonReentrant {
        Price memory priceData = price[tokenIn][tokenOut];
        require(priceData.numerator > 0 && priceData.denominator > 0, PriceNotSet());

        uint8 decimalsIn = IERC20Metadata(tokenIn).decimals();
        uint8 decimalsOut = IERC20Metadata(tokenOut).decimals();
        uint256 amountOut = (amountIn * priceData.numerator * 10 ** decimalsOut) /
            (priceData.denominator * 10 ** decimalsIn);

        uint256 reserveOut = IERC20(tokenOut).balanceOf(address(this));
        require(amountOut <= reserveOut, ReservesExceeded(amountOut, reserveOut));

        IERC20(tokenIn).safeTransferFrom(receiver, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(receiver, amountOut);
    }
}
