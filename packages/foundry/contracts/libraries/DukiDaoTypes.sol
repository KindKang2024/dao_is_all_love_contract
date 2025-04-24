// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DukiDaoTypes {
    struct NetworkConfig {
        address stableCoin;
        address anyrand; // Address of the Anyrand contract for verifiable randomness
        address[] maintainers;
        address[] creators;
    }

    // maybe that is the will evolve. the high level of will has the power and will to care about the all.
    // Thus in Chinese philosophy, The Heaven is the highest level of will and comes first. No conflict with that.
    enum Trigram {
        Earth_Kun_0_Founders, // 8 ☷ Kun 000 - Earth, born and come into existence
        Mountain_Gen_1_Maintainers, // 7 ☶ 001 Gen - Mountain,  survival and  thrive
        Water_Kan_2_Investors, // 6  ☵ Kan 010- Water, investors, empowerment
        Wind_Xun_3_Contributors, //5 ☴ Xun 011- Wind/Wood, Contributors,
        Thunder_Zhen_4_Influencers, //4 ☳ Zhen 100- Thunder, Wills Awakening and Mobilization for Duki in Action, mainly for DUKI influence. Could be KOL and so on
        Fire_Li_5_Community, //3 ☲ Li - Fire, 101 Community, Currently has Lottery, currently be like marketing
        Lake_Dui_6_Nation, // 2 ☱ Dui - 110 Lake/Marsh  suggest 2.5% . (no more than 5% total, need compete with others who do not give; maybe a fitness loss if kindness do not begets kindness)
        Heaven_Qian_7_ALM // 1 ☰ Qian - 111 Heaven/Sky suggest 2.5%

    }

    enum CoinFlowType {
        In,
        Out
    }

    struct CommunityParticipation {
        uint256 participantNo;
        uint256 participantAmount;
        uint256 luckyClaimedRound;
    }

    struct DaoFairDrop {
        uint256 unitAmount; // how much money
        uint256 unitNumber; // how many people can claim that money
        uint256 unitTotal; // current evolution total
    }

    enum InteractType {
        In_To_Service,
        In_To_Extend_Service,
        In_To_Invest,
        Out_Claim_As_Duki4World,
        Out_Claim_As_Duki4Nation,
        Out_Claim_As_CommunityLottery,
        Out_Claim_As_DukiInfluencer,
        Out_Claim_As_Contributor,
        Out_Claim_As_Investor,
        Out_Claim_As_Maintainer,
        Out_Claim_As_Founder
    }

    enum ConfigChangeType {
        LotteryEntryFee
    }

    event ConfigChanged(ConfigChangeType changeType, uint256 previousFee, uint256 newFee, uint256 timestamp);

    event BaguaDukiDaoBpsChanged(uint256[8] beforeBps, uint256[8] afterBps);

    event DukiInAction( // could be empty
        address indexed user,
        InteractType interactType,
        uint256 daoEvolveRound,
        uint256 amount,
        uint256 unitNumber,
        uint256 timestamp,
        string metaDomain
    );

    // events
    event DaoEvolutionWilling(uint256 willId);

    event DaoEvolutionManifestation(
        uint256 indexed daoEvolveRound,
        uint256 willId,
        uint256 randomMutationNumber,
        uint256 communityLuckyNumber,
        DukiDaoTypes.DaoFairDrop[8] fairDrops
    );

    // Errors related to Bagua DAO logic
    error BpsSumError(); // When shares don't sum to PCT_PRECISION
    error BpsTooLargeViolationError(); // some constraints are violated, too big or too small
    error BpsTooSmallViolationError(); // some constraints are violated, too big or too small
    error NoFoundersError(); // When no founders provided
    error ZeroAddressError(); // When founder address is zero
    error NotCommunityLotteryWinner(); // When founder address is zero
    error DuplicateFounderError(); // When duplicate founder address found
    error InvalidTrigramIndexError(); // When trigram index is out of bounds
    error NotOwnerError(); // Message sender is not the owner
    error ClaimedCurrentRoundAlreadyError(); // claimed already
    error AlreadyInvested();
    error InsufficientDistributionAmount(uint256 balance);
    error NoDistributionUnitLeft();
    error InvalidSignature();
    error OnlyAutomationCanCall();
    error DaoEvolutionInProgress();
    error InsufficientPayment(uint256 provided, uint256 required);
    error MustWaitBetweenEvolutions(uint256 lastEvolution, uint256 requiredWait, uint256 currentTime);
    error OnlyMaintainerOrAutomationCanCall();
    error BaguaRoleFull(uint256 roleSeq);
    error NotZkProvedHuman();
    error LateForCurrentClaim(uint256 currentClaimRound, uint256 lateEntryRound);
    error NotHasRole(uint256 roleSeq);
    error NotSupported(string actionNeeded);
    error NoParticipants();
    error InsufficientBalance(uint256 balance, uint256 required);
    error TransferFailed(CoinFlowType t, address other, uint256 amount);
    error RefundFailed();
    error NotQualifiedForClaim(uint256 roleSeq); // Message sender is not the vip supporter
    error InsufficientAllowance(InteractType t, address src, uint256 amount);
}
