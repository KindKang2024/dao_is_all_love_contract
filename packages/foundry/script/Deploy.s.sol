//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./DeployHelpers.s.sol";
import "../contracts/libraries/ISharedStructs.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import { DeployYourContract } from "./DeployYourContract.s.sol";
import { BaguaDukiDaoContract } from "../contracts/BaguaDukiDaoContract.sol";
import { ConfigHelper } from "./ConfigHelper.s.sol";
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import "../contracts/BaguaDukiDaoContract.sol";
import "../contracts/libraries/ISharedStructs.sol";
import "../contracts/dependencies/MyERC20Mock.sol";

import { ERC20DecimalsMock } from "@openzeppelin/contracts/mocks/token/ERC20DecimalsMock.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is ISharedStructs, Script {
    function run() public returns (BaguaDukiDaoContract, NetworkConfig memory) {
        ConfigHelper configHelper = new ConfigHelper();

        NetworkConfig memory config = configHelper.getConfigAsStruct();

        // deploy some dependencies here if needed
        // bytes memory initData = abi.encodeWithSelector(BaguaDukiDaoContract.initialize.selector, config);

        vm.startBroadcast();
        // First deploy the stablecoin if needed
        if (config.stableCoin == address(0)) {
            MyERC20Mock newStableCoin = new MyERC20Mock("USDT", "USDT", config.maintainers[0], 10000 * 10 ** 6);
            config.stableCoin = address(newStableCoin);
        }
        // Now deploy the implementation
        BaguaDukiDaoContract implementation = new BaguaDukiDaoContract(config);
        vm.stopBroadcast();
        // vm.startBroadcast();
        // ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        // vm.stopBroadcast();
        return (implementation, config);
    }
}
