// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ILitePsmWrapper {
    function tout() external view returns (uint256);

    function buyGem(address, uint256) external returns (uint256);
}
