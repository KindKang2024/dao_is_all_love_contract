// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solady/utils/LibString.sol";
import {IDukiBaguaDao}  from   "@/interfaces/IDukiBaguaDao.sol";
import { DukiDaoTypes } from "@/libraries/DukiDaoTypes.sol";


interface IUnstoppableBaguaDao is IDukiBaguaDao {
  struct UnstoppableConfig {
    address unsRegistry;
    address stableCoin;
    address[] maintainers;
    address[] creators;
  }

  struct LotteryQualification {
    uint256 claimedRound;
    uint256 participantNum;
  }

  // like normal airdrop, but emphasize on fairness and duki
  // special: daoFairDrops[0] = AlmFairDrop(distributionAmount, evolveNum, evolveBlockNum);

  struct DaoFairDrop {
    uint256 unitAmount;
    uint256 unitNumber;
    uint256 unitTotal;
  }

  enum ConfigChangeType {
    SubscriptionYearlyFee,
    LotteryEntryFee
  }

  event ConfigChanged(
    ConfigChangeType changeType,
    uint256 previousFee,
    uint256 newFee,
    uint256 timestamp
  );

  event DukiDaoEvolution(
    uint256 daoEvolveNum,
    uint256 winnerNumber,
    DaoFairDrop[9] fairDrops,
    uint256 timestamp
  );

  // enum CoinReceiveType {
  //   Create_Subscription,
  //   Extend_Subscription,
  //   Investment,
  //   LotteryParticipation
  // }

  event UnstoppableEvent(
    address indexed account,
    uint256 indexed evolveNum,
    DukiDaoTypes.InteractType t,
    uint256 amount,
    uint256 units,
    string uns_domain,
    uint256 timestamp
  );

  error SubscriptionExistsError(); // When subscription already exists
  error NotUnsDomainOwnerError(); // Message sender is not the owner
  error LifetimeSubscriptionExceed369(); // maxNum =  369
  error NoNeedExtendLifetimeSubscription();
  error SubscriptionNotExist();
  error SubscriptionYearsInvalid();
  error UnsTestDomainError();
  error UnsSubDomainForbidden();
  error AlreadyEnteredLottery();
  error NotInLottery();
  error NotLotteryWinner();
  error NotHasRole();


  struct BaguaDaoAgg {
    uint256 evolveNum;
    uint256 bornSeconds;
    uint256 subscriptionExpireSeconds;
    uint256 totalClaimedAmount;
    uint256 stableCoinBalance;
    uint256[8] bpsArr;
    uint256[8] bpsNumArr; // how many people in each bps
    // current distribution info
    DaoFairDrop[8] fairDrops;
    uint256 communityLuckyNumber;
    // user info
    uint256[8] claimedRoundArr;
    DukiDaoTypes.CommunityParticipation participation;
  }

  function lotteryQualification(
    address user
  ) external view returns (LotteryQualification memory);

  function expireSecondsOfSubscription(
    string calldata uns_domain
  ) external view returns (uint256);

  function baguaDaoAgg4Me(
    address user,
    string calldata uns_domain
  ) external view returns (BaguaDaoAgg memory);

  // State changing functions
  function payToSubscribe(
    string calldata uns_domain,
    uint32 _subYears
  ) external;

  function payToExtend(
    string calldata uns_domain,
    uint32 _extendYears
  ) external;

  function payToJoinCommunityAndLottery() external;

  function payToInvestUnsInLimo(
    string calldata uns_domain
  ) external;

  function evolveDaoThenDistribute(
    uint32 lotteryWinnerNumber
  ) external returns (bool, uint256);

  // Claim functions
  function claim7_AlmDukiInActionFairDrop(
    string calldata uns_domain
  ) external;

  // function claim6_NationDukiInActionFairDrop() external;

  function claim5_CommunityLotteryDrop() external;
  function claim4_InfluencerFairDrop() external;
  function claim3_ContributorFairDrop() external;
  // invest on the domain name, and also be the lifetime subscription
  function claim2_UnsInvestorFairDrop(
    string calldata uns_domain
  ) external;
  function claim1_MaintainerFairDrop() external;
  function claim0_CreatorFairDrop() external;
}
