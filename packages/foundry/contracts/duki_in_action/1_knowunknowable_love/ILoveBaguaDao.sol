// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDukiBaguaDao } from "@/interfaces/IDukiBaguaDao.sol";
import { DukiDaoTypes } from "@/libraries/DukiDaoTypes.sol";

interface ILoveBaguaDao is IDukiBaguaDao {
    error UnknownWillId(uint256 willId, uint256 expectedWillId);
    error NoPendingRandomnessWill();
    error InvalidKnownStatus();
    error LoveAsMoneyIntoDaoRequired();
    error DaoConnectedAlready();
    error OnlyAnyrandCanCall();

    enum KnownStatus {
        Unknown,
        KnownRight,
        KnownWrong,
        Deprecated
    }

    struct Divination {
        KnownStatus knownStatus;
        bytes32 diviWillHash;
        bytes16 diviWillAnswer;
        uint256 willOfLovePowerAmount;
    }

    event ConnectDaoEvent(
        bytes16 indexed diviId, address diviner, bytes32 diviWillHash, uint256 willDaoPowerAmount, uint256 timestamp
    );

    event VowDaoEvent(
        bytes16 indexed diviId, address diviner, KnownStatus knownStatus, uint256 vowDaoPowerAmount, uint256 timestamp
    );

    struct BaguaDaoAgg {
        uint256 evolveNum;
        uint256 bornSeconds;
        uint256 totalClaimedAmount;
        uint256 stableCoinBalance;
        uint256[8] bpsArr;
        uint256[8] bpsNumArr; // how many people in each bps
        // current distribution info
        DukiDaoTypes.DaoFairDrop[8] fairDrops;
        uint256 communityLuckyNumber;
        // user info
        uint256[8] claimedRoundArr;
        DukiDaoTypes.CommunityParticipation participation;
    }

    function connectDaoToKnow(bytes16 diviUuid, bytes32 diviWillHash, bytes16 diviWillAnswer, uint256 willPowerAmount)
        external;

    // after verified the divination, the user can vow to the dao
    function vowDaoManifestation(bytes16 diviUuid, KnownStatus knownStatus, uint256 vowPowerAmount) external;

    function baguaDaoAgg4Me(address user) external view returns (BaguaDaoAgg memory);

    // The two functions are controlled by the founder and maintainer;
    function approveAsContributor(address requestor) external;
    function approveAsDukiInfluencer(address requestor) external;
    function connectDaoToInvest() external;

    function requestDaoEvolution(uint256 callbackGasLimit) external payable returns (uint256);
    function tryAbortDaoEvolution() external;

    // Claim functions
    function claim7Love_WorldDukiInActionFairDrop() external;
    function claim6Love_NationDukiInActionFairDrop() external;
    function claim5Love_CommunityLotteryFairDrop() external;
    function claim4Love_DukiInfluencerFairDrop() external;
    function claim3Love_ContributorFairDrop() external;
    function claim2Love_InvestorFairDrop() external;
    function claim1Love_MaintainerFairDrop() external;
    function claim0Love_FounderFairDrop() external;
}
