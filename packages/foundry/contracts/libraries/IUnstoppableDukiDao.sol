// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISharedStructs.sol";
import { IBaguaDukiDao } from "./IBaguaDukiDao.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUnstoppableDukiDao is ISharedStructs {
    function totalStableCoin() external view returns (uint256);

    function stableCoinAddress() external view returns (address);
    function uniRegistryAddress() external view returns (address);

    function lotteryQualification(address user) external view returns (LotteryQualification memory);

    function baguaDaoUnitCountArr() external view returns (uint256[9] memory);
    function baguaDaoFairDropArr() external view returns (DaoFairDrop[9] memory);
    function baguaDaoBpsArr() external view returns (uint256[9] memory);

    function expireSecondsOfSubscription(string calldata uns_domain) external view returns (uint256);

    function buaguaDaoAgg4Me(address user, string calldata uns_domain) external view returns (BaguaDaoAgg memory);

    // State changing functions
    function payToSubscribe(string calldata uns_domain, uint32 _subYears) external;

    function payToExtend(string calldata uns_domain, uint32 _extendYears) external;

    function payToJoinCommunityAndLottery() external;

    function payToInvestUnsInLimo(string calldata uns_domain) external;

    function evolveDaoThenDistribute(uint32 lotteryWinnerNumber) external returns (bool, uint256);

    // Claim functions
    function claim1_AlmDukiInActionFairDrop(string calldata uns_domain) external;

    // function claimNationFairDrop() external;

    function claim3_CommunityLotteryDrop() external;
    function claim4_BuilderFairDrop() external;
    function claim5_ContributorFairDrop() external;
    // invest on the domain name, and also be the lifetime subscription
    function claim6_UnsInvestorFairDrop(string calldata uns_domain) external;
    function claim7_MaintainerFairDrop() external;
    function claim8_CreatorFairDrop() external;
}
