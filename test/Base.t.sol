// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Base is Test {
    struct Roles {
        address defaultAdmin;
        address whitelistManager;
    }

    struct Users {
        address alice;
        uint256 alicePrivateKey;
        address bob;
        address charlie;
    }

    Roles internal roles;
    Users internal users;
    address internal shiftSwapRouter;

    bytes32 internal constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");

    function setUp() public virtual {
        roles.defaultAdmin = makeAddr("DEFAULT_ADMIN");
        roles.whitelistManager = makeAddr("WHITELIST_MANAGER");

        (address alice, uint256 alicePrivateKey) = makeAddrAndKey("ALICE");
        users.alice = alice;
        users.alicePrivateKey = alicePrivateKey;
        users.bob = makeAddr("BOB");
        users.charlie = makeAddr("CHARLIE");
    }
}
