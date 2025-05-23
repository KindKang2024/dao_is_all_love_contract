//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../DeployHelpers.s.sol";
import { ConfigHelper } from "./ConfigHelper.s.sol";
import { AnyrandMock } from "@/dependencies/mocks/AnyrandMock.sol";
import { ILoveBaguaDao } from "@/duki_in_action/1_knowunknowable_love/ILoveBaguaDao.sol";
/**
 * @notice Main deployment script for all contracts
 * @dev Run this when you want to deploy multiple contracts at once
 * yarn deploy --network localhost --file DeployAnyrandMockContract.s.sol
 *
 * Example: yarn deploy # runs this script(without`--file` flag)
 */

contract DeployAnyrandMockContract is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner {
        new AnyrandMock();
    }
}
