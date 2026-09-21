// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {UniswapV3SwapRouter02AdapterBase} from "test/unit/UniswapV3SwapRouter02Adapter/UniswapV3SwapRouter02AdapterBase.t.sol";

contract UniswapV3SwapRouter02AdapterPathTest is UniswapV3SwapRouter02AdapterBase {
    function test_WhitelistPathSingleHop() public {
        bytes memory path = _whitelistPath();

        assertEq(uniswapV3Adapter.whitelistedPaths(path), true, "test_WhitelistPathSingleHop: path is not whitelisted");

        (address[] memory decodedTokens, uint24[] memory decodedFees) = uniswapV3Adapter.decodePath(path);

        assertEq(decodedTokens.length, 2, "test_WhitelistPathSingleHop: decodedTokens.length is incorrect");
        assertEq(decodedFees.length, 1, "test_WhitelistPathSingleHop: decodedFees.length is incorrect");

        assertEq(decodedTokens[0], address(tokenA), "test_WhitelistPathSingleHop: decodedTokens[0] is incorrect");
        assertEq(decodedTokens[1], address(tokenB), "test_WhitelistPathSingleHop: decodedTokens[1] is incorrect");
        assertEq(decodedFees[0], FEE, "test_WhitelistPathSingleHop: decodedFees[0] is incorrect");
    }

    function test_BlacklistPathSingleHop() public {
        bytes memory path = _whitelistPath();

        vm.prank(roles.whitelistManager);
        uniswapV3Adapter.blacklistPath(path);

        assertEq(
            uniswapV3Adapter.whitelistedPaths(path),
            false,
            "test_BlacklistPathSingleHop: path is still whitelisted"
        );
    }

    function test_RevertIf_WhitelistPath_NotWhitelistManager() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);

        uint24[] memory fees = new uint24[](1);
        fees[0] = FEE;

        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("NotWhitelistManager(address)")), users.alice));
        uniswapV3Adapter.whitelistPath(tokens, fees);
    }
}
