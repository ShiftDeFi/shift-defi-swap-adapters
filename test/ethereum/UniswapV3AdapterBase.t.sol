// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {UniswapV3Adapter} from "contracts/UniswapV3Adapter.sol";
import {IUniswapV3Adapter} from "contracts/interfaces/IUniswapV3Adapter.sol";
import {IUniswapV3Factory} from "contracts/dependencies/uniswap-v3/IUniswapV3Factory.sol";

import {Base} from "test/Base.t.sol";

contract UniswapV3AdapterBase is Base {
    IUniswapV3Factory internal constant UNISWAP_V3_FACTORY =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address internal constant UNISWAP_V3_ADAPTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IUniswapV3Adapter internal uniswapV3Adapter;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public virtual override {
        super.setUp();

        shiftSwapRouter = 0x14D3f12063209FBE9D11117F4a78a3a620622F93;
        vm.label(shiftSwapRouter, "SHIFT_SWAP_ROUTER");
        uniswapV3Adapter = new UniswapV3Adapter(roles.defaultAdmin, UNISWAP_V3_ADAPTER);
        vm.label(address(uniswapV3Adapter), "UNISWAP_V3_ADAPTER");

        vm.prank(roles.defaultAdmin);
        AccessControl(address(uniswapV3Adapter)).grantRole(WHITELIST_MANAGER_ROLE, roles.whitelistManager);
    }

    function _verifyPath(address[] memory tokens, uint24[] memory fees) internal view returns (bool) {
        require(tokens.length == fees.length + 1, IUniswapV3Adapter.InvalidPathLengths(tokens.length, fees.length));

        for (uint i = 0; i < fees.length; i++) {
            address pool = UNISWAP_V3_FACTORY.getPool(tokens[i], tokens[i + 1], fees[i]);
            if (pool == address(0)) {
                return false;
            }
        }
        return true;
    }
}
