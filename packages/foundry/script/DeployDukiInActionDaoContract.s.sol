// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/BaguaDukiDaoContract.sol";
import "./ConfigHelper.s.sol";

/**
 * @notice Deploy script for YourContract contract
 * @dev Inherits ScaffoldETHDeploy which:
 *      - Includes forge-std/Script.sol for deployment
 *      - Includes ScaffoldEthDeployerRunner modifier
 *      - Provides `deployer` variable
 * Example:
 * yarn deploy --file DeployYourContract.s.sol  # local anvil chain
 * yarn deploy --file DeployYourContract.s.sol --network optimism # live network (requires keystore)
 */
contract DeployDukiInActionDaoContract is ScaffoldETHDeploy {
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`:
     *      - "scaffold-eth-default": Uses Anvil's account #9 (0xa0Ee7A142d267C1f36714E4a8F75612F20a79720), no password prompt
     *      - "scaffold-eth-custom": requires password used while creating keystore
     *
     * Note: Must use ScaffoldEthDeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external ScaffoldEthDeployerRunner {
        ConfigHelper configHelper = new ConfigHelper();
        NetworkConfig memory config = configHelper.getConfigAsStruct();

        new BaguaDukiDaoContract();
    }

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
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

    function getOrCreateAnvilEthConfig() internal view returns (NetworkConfig memory config) {
        // string memory ownerStr = vm.envString("OWNER");
        // console2.log("Owner String :", ownerStr);
        // address owner = address(bytes20(bytes(ownerStr)));

        uint256 maintainersLength = vm.envUint("MAINTAINERS_LENGTH");
        address[] memory maintainers = new address[](maintainersLength);

        for (uint256 i = 1; i <= maintainersLength; i++) {
            console2.log("begin maintainersAddress setup ", i);
            string memory addrString = vm.envString(string.concat("MAINTAINERS_", vm.toString(i)));
            // Convert the string to an address and store it in the array
            maintainers[i - 1] = address(bytes20(bytes(addrString)));
        }

        uint256 creatersLength = vm.envUint("CREATORS_LENGTH");
        address[] memory creators = new address[](creatersLength);

        for (uint256 i = 1; i <= creatersLength; i++) {
            string memory addrString = vm.envString(string.concat("CREATORS_", vm.toString(i)));
            // Convert the string to an address and store it in the array
            creators[i - 1] = address(bytes20(bytes(addrString)));
        }

        console2.log("creatorsAddress setup");

        // Do something with myAddress
        // 0xAb005176D74900A9c25fDA144e2f9f329A409166

        address unsRegistryAddr = getDependencAddress("UNS_REGISTRY_ADDRESS");
        address stableCoinAddr = getDependencAddress("STABLE_COIN_ERC20_ADDRESS");

        return NetworkConfig({
            unsRegistry: unsRegistryAddr,
            stableCoin: stableCoinAddr,
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

    function getConfigAsStruct() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
