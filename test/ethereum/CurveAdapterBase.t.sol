// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CurveAdapter} from "contracts/CurveAdapter.sol";
import {ICurveAdapter} from "contracts/interfaces/ICurveAdapter.sol";
import {EthereumBase} from "test/ethereum/EthereumBase.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract CurveAdapterBaseTest is EthereumBase {
    using SafeERC20 for IERC20;

    CurveAdapter internal curveAdapter;

    function setUp() public virtual override {
        super.setUp();

        curveAdapter = new CurveAdapter(roles.defaultAdmin, CURVE_ROUTER, roles.whitelistManager);
        vm.label(address(curveAdapter), "CURVE_ADAPTER");
    }

    function _whitelistPath(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) internal {
        vm.prank(roles.whitelistManager);
        curveAdapter.whitelistPath(tokenIn, tokenOut, route, swapParams, pools);
    }

    function _computeKey(
        address tokenIn,
        address tokenOut,
        address[11] memory route,
        uint256[5][5] memory swapParams,
        address[5] memory pools
    ) internal pure returns (bytes32 key) {
        bytes memory data = abi.encode(tokenIn, tokenOut, route, swapParams, pools);
        assembly {
            key := keccak256(add(data, 0x20), mload(data))
        }
    }

    function _input()
        internal
        pure
        returns (address[11] memory route, address[5] memory pools, uint256[5][5] memory swapParams)
    {
        route = [
            WETH,
            CURVE_TRICRYPTO_OPTIMIZED_WETH,
            CRVUSD,
            SUSDE_CRVUSD_POOL,
            SUSDE,
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0)
        ];
        pools = [CURVE_TRICRYPTO_OPTIMIZED_WETH, SUSDE_CRVUSD_POOL, address(0), address(0), address(0)];
        swapParams = [
            [uint256(1), 0, 1, 30, 3],
            [uint256(0), 1, 1, 10, 2],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0]
        ];
    }
}
