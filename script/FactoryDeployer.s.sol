// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {VolunteerFactory} from "../src/Factory.sol";

contract FactoryDeployer is Script {
    VolunteerFactory factory;

    function run() public returns (VolunteerFactory) {
        vm.startBroadcast();
        factory = new VolunteerFactory();
        vm.stopBroadcast();
        return factory;
    }
}
