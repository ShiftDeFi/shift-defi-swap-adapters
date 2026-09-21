// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev The real WMON contract on Monad (0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A)
/// is a WETH9-style wrapper; confirmed via its bytecode selectors (`deposit()`,
/// `symbol()`, `decimals()`, `transfer`, `balanceOf`, `allowance`).
interface IWMON is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
