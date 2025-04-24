// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@forge-std/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Script} from "forge-std/Script.sol";
import {Script, console} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {DukiDaoTypes} from "@/libraries/DukiDaoTypes.sol";

contract ConfigHelper is Script {
    DukiDaoTypes.NetworkConfig public activeNetworkConfig;

    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;

    //   uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
    //     0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        // if (block.chainid == 11_155_111) {
        //   activeNetworkConfig = getSepoliaEthConfig();
        //   }
        activeNetworkConfig = getOrCreateAnvilEthConfig();
    }

    function getOrCreateAnvilEthConfig() internal view returns (DukiDaoTypes.NetworkConfig memory config) {
        // string memory ownerStr = vm.envString("OWNER");
        // console2.log("Owner String :", ownerStr);
        // address owner = address(bytes20(bytes(ownerStr)));

        uint256 maintainersLength = vm.envUint("MAINTAINERS_LENGTH");
        address[] memory maintainers = new address[](maintainersLength);

        for (uint256 i = 1; i <= maintainersLength; i++) {
            string memory addrString = vm.envString(string.concat("MAINTAINERS_", vm.toString(i)));
            // Convert the string to an address and store it in the array
            maintainers[i - 1] = vm.parseAddress(addrString);
            console2.log("maintainersAddress", i, addrString, maintainers[i - 1]);
            //   maintainersAddress 1 0x70F0f595b9eA2E3602BE780cc65263513A72bba3 0x3078373046306635393562396541324533363032
        }

        uint256 creatersLength = vm.envUint("CREATORS_LENGTH");
        address[] memory creators = new address[](creatersLength);

        for (uint256 i = 1; i <= creatersLength; i++) {
            string memory addrString = vm.envString(string.concat("CREATORS_", vm.toString(i)));
            // Convert the string to an address and store it in the array
            //   creators[i - 1] = address(bytes20(bytes(addrString))); buggy
            creators[i - 1] = vm.parseAddress(addrString);
            console2.log("creatorsAddress", i, addrString, creators[i - 1]);
        }

        console2.log("creatorsAddress setup");

        // Do something with myAddress
        // 0xAb005176D74900A9c25fDA144e2f9f329A409166

        address stableCoinAddr = getDependencAddress("STABLE_COIN_ERC20_ADDRESS");
        address anyrandAddr = getDependencAddress("ANYRAND_ADDRESS");

        return DukiDaoTypes.NetworkConfig({
            stableCoin: stableCoinAddr,
            anyrand: anyrandAddr,
            maintainers: maintainers,
            creators: creators
        });
    }

    function getDependencAddress(string memory contractName) public view returns (address) {
        string memory contractAddrRaw = vm.envOr(contractName, string(""));
        bool contractAddrRawGotten = (bytes(contractAddrRaw).length <= 0);
        // address unsRegistry;
        // address stableCoin;
        // string memory unsRegistryRaw = vm.envOr("UnsRegistryContract", string(""));
        // string memory stableCoinRaw = vm.envOr("StableCoinContract", string(""));
        // bool unsRegistryMocked = (bytes(unsRegistryRaw).length <= 0);
        // bool stableCoinMocked = bytes(stableCoinRaw).length <= 0;

        // string memory keystorePath = vm.envString("ETH_KEYSTORE_ACCOUNT");
        // if (keccak256(bytes(unsRegistryRaw)) != keccak256(bytes(""))) {
        //   unsRegistry = address(bytes20(bytes(unsRegistryRaw)));
        // }
        // }
        // if (bytes(stableCoinRaw).length > 0) {
        //      stableCoin = address(bytes20(bytes(stableCoinRaw)));
        // }
        if (!contractAddrRawGotten) {
            return vm.parseAddress(contractAddrRaw);
        }
        return address(0);
    }

    function getConfigAsStruct() public view returns (DukiDaoTypes.NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
