// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {WmonUsdt0MonadAdapter} from "contracts/custom-adapters/monad/WmonUsdt0MonadAdapter.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();
        WmonUsdt0MonadAdapter adapter = new WmonUsdt0MonadAdapter();
        vm.stopBroadcast();

        console.log("WmonUsdt0MonadAdapter deployed at: %s", address(adapter));
    }
}
