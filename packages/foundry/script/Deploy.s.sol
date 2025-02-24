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
import "../test/mock/MyERC20Mock.sol";

import { ERC20DecimalsMock } from "@openzeppelin/contracts/mocks/token/ERC20DecimalsMock.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is ISharedStructs, Script {
    function run() public returns (BaguaDukiDaoContract, NetworkConfig memory) {
        ConfigHelper configHelper = new ConfigHelper();

        NetworkConfig memory config = configHelper.getConfigAsStruct();

        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        console2.log("Config for stableCoin :", config.stableCoin);
        // string memory deployerKeyHex = Strings.toHexString(deployerKey);
        bool deploy_dependencies = config.stableCoin == address(0);

        vm.startBroadcast();
        if (deploy_dependencies) {
            address testAccount = vm.envAddress("TEST_INTERACT_ACCOUNT");

            // WHy Deal do not works?
            // console2.log("Before deal, balance:", testAccount.balance);
            // deal(testAccount, 1000000000000000000000);
            // console2.log("After deal, balance:", testAccount.balance);

            string[] memory labels = new string[](2);
            labels[0] = "kindkang";
            labels[1] = "unstoppable";

            MyERC20Mock stableCoin = new MyERC20Mock("USDC", "USDC", testAccount, 10000);

            config.stableCoin = address(stableCoin);

            console2.log("deploy_dependencies stableCoin", config.stableCoin);
        } else {
            console2.log("env stableCoin", config.stableCoin);
        }

        bytes memory initData = abi.encodeWithSelector(BaguaDukiDaoContract.initialize.selector, config);

        BaguaDukiDaoContract implementation = new BaguaDukiDaoContract();
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        vm.stopBroadcast();

        return (BaguaDukiDaoContract(payable(address(proxy))), config);
    }
}
