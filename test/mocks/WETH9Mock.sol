// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/// @dev ERC20Mock plus WETH9's `deposit`, enough for SwapRouter02Mock to wrap
/// its own native balance the way the real router does.
contract WETH9Mock is ERC20Mock {
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }
}
