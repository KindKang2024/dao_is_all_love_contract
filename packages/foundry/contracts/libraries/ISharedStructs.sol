// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IBaguaDukiDao } from "./IBaguaDukiDao.sol";

interface ISharedStructs is IBaguaDukiDao {
    struct NetworkConfig {
        address stableCoin;
        address anyrand; // Address of the Anyrand contract for verifiable randomness
        address[] maintainers;
        address[] creators;
    }

    struct CommunityParticipation {
        uint256 participantNo;
        uint256 participantAmount;
        uint256 luckyClaimedRound;
    }

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

    struct BaguaDaoAgg {
        uint256 evolveNum;
        uint256 bornSeconds;
        uint256 totalClaimedAmount;
        uint256 stableCoinBalance;
        uint256[8] bpsArr;
        uint256[8] bpsNumArr; // how many people in each bps
        // current distribution info
        DaoFairDrop[8] fairDrops;
        uint256 communityLuckyNumber;
        // user info
        bool[8] claimQualificationArr;
        CommunityParticipation participation;
    }

    struct DaoFairDrop {
        uint256 unitAmount; // how much money
        uint256 unitNumber; // how many people can claim that money
    }

    enum ConfigChangeType {
        LotteryEntryFee
    }

    event DukiInAction(
        address user,
        InteractType interactType,
        uint256 daoEvolveRound,
        uint256 amount,
        uint256 unitNumber,
        uint256 timestamp
    );

    event ConfigChanged(ConfigChangeType changeType, uint256 previousFee, uint256 newFee, uint256 timestamp);

    event DaoEvolutionWilling(uint256 willId, uint256 timestamp);

    event DaoEvolutionRepresentation(
        uint256 willId,
        uint256 randomMutationNumber,
        uint256 communityLuckyNumber,
        uint256 daoEvolveRound,
        DaoFairDrop[8] fairDrops,
        uint256 timestamp
    );

    event ConnectDaoEvent(
        address diviner,
        bytes16 diviId,
        bytes32 diviWillHash,
        uint256 timestamp
    );
    event VowDaoEvent(
        address diviner,
        bytes16 diviId,
        KnownStatus knownStatus,
        uint256 timestamp
    );


    enum InteractType {
        In_To_Divine,
        In_To_Invest,
        Out_Claim_As_Duki4World,
        Out_Claim_As_Duki4Nation,
        Out_Claim_As_CommunityLottery,
        Out_Claim_As_Builder,
        Out_Claim_As_Contributor,
        Out_Claim_As_Investor,
        Out_Claim_As_Maintainer,
        Out_Claim_As_Founder
    }

    error InvertorsFullExceed369(); // maxNum =  369
    error NotZkProvedHuman();
    error LateForCurrentClaim(uint256 currentClaimRound, uint256 lateEntryRound);
    error NotQualifiedForClaim(InteractType t); // Message sender is not the vip supporter
    error InsufficientAllowance(InteractType t, address src, uint256 amount);
    error NotHasRole();
    error NotSupported(string actionNeeded);
    error NoParticipants();
    error InsufficientBalance(uint256 balance, uint256 required);
    error InvalidKnownStatus();
}
