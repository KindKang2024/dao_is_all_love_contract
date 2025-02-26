//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/libraries/ISharedStructs.sol";
import { ConfigHelper } from "./ConfigHelper.s.sol";
import { MyERC20Mock } from "../contracts/dependencies/mocks/MyERC20Mock.sol";

/**
 * @notice Main deployment script for all contracts
 * @dev Run this when you want to deploy multiple contracts at once
 * yarn deploy --network localhost --file DeployUsdtMockContract.s.sol
 * Example: yarn deploy # runs this script(without`--file` flag)
 */
contract DeployUsdtMockContract is ScaffoldETHDeploy, ISharedStructs {
    address testAccountMockAddress = 0x70F0f595b9eA2E3602BE780cc65263513A72bba3;

    function run() external ScaffoldEthDeployerRunner {
        new MyERC20Mock("USDT", "USDT", testAccountMockAddress, 10000 * 10 ** 6);
    }
}
