// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";

import {OneInchAdapter} from "contracts/OneInchAdapter.sol";

contract DeployOneInchAdapterScript is Script {
    address public constant ONE_INCH_ROUTER = 0x111111125421cA6dc452d289314280a0f8842A65;

    function run() public {
        vm.startBroadcast();
        new OneInchAdapter(ONE_INCH_ROUTER);
        vm.stopBroadcast();
    }
}
