// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {UniswapV3Adapter} from "contracts/UniswapV3Adapter.sol";
import {IUniswapV3Adapter} from "contracts/interfaces/IUniswapV3Adapter.sol";
import {EthereumBase} from "test/ethereum/EthereumBase.t.sol";

contract UniswapV3AdapterBase is EthereumBase {
    IUniswapV3Adapter internal uniswapV3Adapter;

    function setUp() public virtual override {
        super.setUp();

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
