// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {UniswapV3AdapterBase} from "test/ethereum/UniswapV3AdapterBase.t.sol";
import {console2 as console} from "forge-std/console2.sol";

contract UniswapV3AdapterPathsTest is UniswapV3AdapterBase {
    using SafeERC20 for IERC20;

    function test_WhitelistPathSingleHop() public {
        address[] memory tokens = new address[](2);
        tokens[0] = DAI;
        tokens[1] = USDC;

        uint24[] memory fees = new uint24[](1);
        fees[0] = 100;

        vm.prank(roles.whitelistManager);
        bytes memory path = uniswapV3Adapter.whitelistPath(tokens, fees);

        assertEq(uniswapV3Adapter.whitelistedPaths(path), true, "test_WhitelistPathSingleHop: path is not whitelisted");

        (address[] memory decodedTokens, uint24[] memory decodedFees) = uniswapV3Adapter.decodePath(path);

        assertEq(decodedTokens.length, 2, "test_WhitelistPathSingleHop: decodedTokens.length is incorrect");
        assertEq(decodedFees.length, 1, "test_WhitelistPathSingleHop: decodedFees.length is incorrect");

        assertEq(decodedTokens[0], tokens[0], "test_WhitelistPathSingleHop: decodedTokens[0] is incorrect");
        assertEq(decodedTokens[1], tokens[1], "test_WhitelistPathSingleHop: decodedTokens[1] is incorrect");
        assertEq(decodedFees[0], fees[0], "test_WhitelistPathSingleHop: decodedFees[0] is incorrect");

        assertTrue(_verifyPath(tokens, fees), "test_WhitelistPathSingleHop: path is not valid");
    }
}
