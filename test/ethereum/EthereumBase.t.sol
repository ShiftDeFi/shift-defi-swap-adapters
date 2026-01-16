// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Base} from "test/Base.t.sol";
import {IUniswapV3Factory} from "contracts/dependencies/uniswap-v3/IUniswapV3Factory.sol";
import {IUniswapV3Adapter} from "contracts/interfaces/IUniswapV3Adapter.sol";

abstract contract EthereumBase is Base {
    address internal constant CURVE_ROUTER = 0x45312ea0eFf7E09C83CBE249fa1d7598c4C8cd4e;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CURVE_TRICRYPTO_OPTIMIZED_WETH = 0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14;
    address internal constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    address internal constant SUSDE_CRVUSD_POOL = 0x57064F49Ad7123C92560882a45518374ad982e85;
    address internal constant SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant UNISWAP_V3_ADAPTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IUniswapV3Factory internal constant UNISWAP_V3_FACTORY =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    function setUp() public virtual override {
        super.setUp();

        shiftSwapRouter = 0x14D3f12063209FBE9D11117F4a78a3a620622F93;
        vm.label(shiftSwapRouter, "SHIFT_SWAP_ROUTER");

        vm.label(CURVE_ROUTER, "CURVE_ROUTER");
        vm.label(WETH, "WETH");
        vm.label(CURVE_TRICRYPTO_OPTIMIZED_WETH, "CURVE_TRICRYPTO_OPTIMIZED_WETH");
        vm.label(CRVUSD, "CRVUSD");
        vm.label(SUSDE_CRVUSD_POOL, "SUSDE_CRVUSD_POOL");
        vm.label(SUSDE, "SUSDE");
    }
}
