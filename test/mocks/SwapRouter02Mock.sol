// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {ISwapRouter02} from "contracts/dependencies/uniswap-v3/ISwapRouter02.sol";

/// @dev Minimal SwapRouter02 stand-in: pulls the path's first token from the
/// caller and mints the path's last token 1:1 to the recipient. `fillAmount`
/// simulates a pool running out of liquidity - when non-zero, only that much
/// input is pulled, mirroring SwapRouter02's partial-fill behaviour.
contract SwapRouter02Mock is ISwapRouter02 {
    uint256 public fillAmount;

    function setFillAmount(uint256 _fillAmount) external {
        fillAmount = _fillAmount;
    }

    function exactInput(ExactInputParams memory params) external payable returns (uint256 amountOut) {
        bytes memory path = params.path;
        address tokenIn;
        address tokenOut;
        assembly {
            tokenIn := shr(96, mload(add(path, 0x20)))
            tokenOut := shr(96, mload(add(path, add(0x20, sub(mload(path), 20)))))
        }

        uint256 amountIn = fillAmount == 0 ? params.amountIn : fillAmount;
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        amountOut = amountIn;
        require(amountOut >= params.amountOutMinimum, "Too little received");
        ERC20Mock(tokenOut).mint(params.recipient, amountOut);
    }
}
