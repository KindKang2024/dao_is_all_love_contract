// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IBaguaDukiDao } from "./IBaguaDukiDao.sol";

interface ISharedStructs is IBaguaDukiDao {
    struct NetworkConfig {
        address stableCoin;
        address[] maintainers;
        address[] creators;
    }

    struct LotteryQualification {
        uint256 claimedRound;
        uint256 participantNum;
    }

    struct BaguaDaoAgg {
        uint256 bornSeconds;
        uint256 subscriptionExpireSeconds;
        uint256 lotteryWinnerNumber;
        uint256 lotteryParticipantNum; // community seq number , determines lottery winned or not
        uint256 claimedAmount;
        uint256[9] claimedRoundArr; // the first one is distribution evolved block number, others are users, could be 0 means not in
        uint256[9] bpsArr;
        uint256[9] num;
        // like normal airdrop, but emphasize on fairness and duki
        // special: daoFairDrops[0] = AlmFairDrop(distributionAmount, evolveNum, evolveBlockNum );
        DaoFairDrop[9] fairDrops;
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

    event ConfigChanged(ConfigChangeType changeType, uint256 previousFee, uint256 newFee, uint256 timestamp);

    event DukiDaoEvolution(uint256 daoEvolveNum, uint256 winnerNumber, DaoFairDrop[9] fairDrops, uint256 timestamp);

    // enum CoinReceiveType {
    //   Create_Subscription,
    //   Extend_Subscription,
    //   Investment,
    //   LotteryParticipation
    // }

    enum InteractType {
        In_To_Create_Subscription,
        In_To_Extend_Subscription,
        In_To_Invest_Unstoppable_Domain,
        In_To_Community_Lottery,
        Out_Claim1_As_Duki4World,
        Out_Claim2_As_Duki4Nation,
        Out_Claim3_As_CommunityStar,
        Out_Claim4_As_Builder,
        Out_Claim5_As_Contributor,
        Out_Claim6_As_Investor,
        Out_Claim7_As_Maintainer,
        Out_Claim8_As_Creator
    }

    event UnstoppableEvent(
        address indexed account,
        uint256 indexed evolveNum,
        InteractType t,
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
    error LateForCurrentClaim(uint256 currentClaimRound, uint256 lateEntryRound);
    error NotQualifiedForClaim(InteractType t); // Message sender is not the vip supporter
    error InsufficientAllowance(InteractType t, address src, uint256 amount);
    error AlreadyEnteredLottery();
    error NotInLottery();
    error NotLotteryWinner();
    error NotHasRole();
}
