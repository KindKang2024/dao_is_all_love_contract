// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";
//import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {LoveDaoContract} from "@/duki_in_action/1_knowunknowable_love/LoveDaoContract.sol";

/**
 * yarn deploy --network localhost --file Upgrade.s.sol
 * yarn deploy --network localhost --file  duki_in_action/1_knowunknowable_love/Upgrade.s.sol
 */
contract UpgradeScript is Script {
    function run() public returns (address, address) {
        address mostRecentlyDeployedProxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);

        // Hardcode proxy address for convenience
        // address proxyAddress = 0x238213078DbD09f2D15F4c14c02300FA1b2A81BB;

        vm.startBroadcast();
        LoveDaoContract newImplementation = new LoveDaoContract();
        vm.stopBroadcast();

        address proxy = upgradeBox(mostRecentlyDeployedProxy, address(newImplementation));

        console2.log("new newImplementation", address(newImplementation));

        // 返回代理合约的接口
        return (proxy, address(newImplementation));
    }

    function upgradeBox(address proxyAddress, address newBox) public returns (address) {
        vm.startBroadcast();
        LoveDaoContract proxy = LoveDaoContract(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newBox), "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
