//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./DeployHelpers.s.sol";
import "@/duki_in_action/1_knowunknowable_love/ILoveBaguaDao.sol";
import "@/duki_in_action/1_knowunknowable_love/LoveDaoContract.sol";
// import { DeployYourContract } from "./DeployYourContract.s.sol";
import "@/dependencies/mocks/AnyrandMock.sol";
import "@/dependencies/mocks/MyERC20Mock.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
import { ConfigHelper } from "./ConfigHelper.s.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import { ERC20DecimalsMock } from "@openzeppelin/contracts/mocks/token/ERC20DecimalsMock.sol";
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import {LoveDaoContract} from "@/duki_in_action/1_knowunknowable_love/LoveDaoContract.sol";
import {DukiDaoTypes} from "@/libraries/DukiDaoTypes.sol";
/**
 * yarn deploy --network localhost --file Deploy.s.sol
 */
contract LoveDeployScript is Script {
    function run() public returns (LoveDaoContract, DukiDaoTypes.NetworkConfig memory) {
        ConfigHelper configHelper = new ConfigHelper();

        DukiDaoTypes.NetworkConfig memory config = configHelper.getConfigAsStruct();

        vm.startBroadcast();
        // First deploy the stablecoin if needed
        if (config.stableCoin == address(0)) {
            MyERC20Mock newStableCoin = new MyERC20Mock("USDC", "USDC", config.maintainers[0], 10000 * 10 ** 6);
            config.stableCoin = address(newStableCoin);
        }
        if (config.anyrand == address(0)) {
            AnyrandMock newAnyrand = new AnyrandMock();
            config.anyrand = address(newAnyrand);
        }
        // Now deploy the implementation
        LoveDaoContract implementation = new LoveDaoContract();

        // deploy some dependencies here if needed
        bytes memory initData = abi.encodeWithSelector(LoveDaoContract.initialize.selector, config);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        vm.stopBroadcast();
        return (LoveDaoContract(payable(address(proxy))), config);
    }
}
