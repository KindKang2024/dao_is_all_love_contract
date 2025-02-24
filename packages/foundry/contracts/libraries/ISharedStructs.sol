// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IBaguaDukiDao } from "./IBaguaDukiDao.sol";

interface ISharedStructs is IBaguaDukiDao {
    struct NetworkConfig {
        address stableCoin;
        address[] maintainers;
        address[] creators;
    }

    struct CommunityParticipation {
        uint256 claimedRound;
        uint256 participantNo;
    }

    struct BaguaDaoAgg {
        uint256 bornSeconds;
        uint256 totalClaimedAmount;
        uint256[8] bpsArr;
        uint256[8] bpsNumArr; // how many people in each bps
        // like normal airdrop, but emphasize on fairness and duki
        // special: daoFairDrops[0] = AlmFairDrop(distributionAmount, evolveNum, evolveBlockNum );
        // current distribution info
        DaoFairDrop[8] curFairDrops;
        uint256[3] luckyCommunityParticipants;
        // user info
        uint256[8] userClaimedRoundArr;
        uint256 userParticipantNo; // community seq number , determines lottery winned or not
    }

    // like normal airdrop, but emphasize on fairness and duki
    // special: daoFairDrops[0] = AlmFairDrop(distributionAmount, evolveNum, evolveBlockNum);

    struct DaoFairDrop {
        uint256 unitAmount; // how much money
        uint256 unitNumber; // how many people can claim that money
        uint256 unitTotal; //abundant because of laziness
    }

    enum ConfigChangeType {
        LotteryEntryFee
    }

    event DukiInActionEvent(
        address user,
        InteractType interactType,
        uint256 daoEvolveNum,
        uint256 amount,
        uint256 unitNumber,
        uint256 timestamp
    );

    event ConfigChanged(ConfigChangeType changeType, uint256 previousFee, uint256 newFee, uint256 timestamp);

    event DukiDaoEvolution(
        uint256 daoEvolveNum, uint256[3] luckyParticantsNumber, DaoFairDrop[8] fairDrops, uint256 timestamp
    );

    enum InteractType {
        In_To_Invest,
        In_To_Divine,
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
    error LateForCurrentClaim(uint256 currentClaimRound, uint256 lateEntryRound);
    error NotQualifiedForClaim(InteractType t); // Message sender is not the vip supporter
    error InsufficientAllowance(InteractType t, address src, uint256 amount);
    error NotHasRole();
    error NotSupported(string actionNeeded);
}
