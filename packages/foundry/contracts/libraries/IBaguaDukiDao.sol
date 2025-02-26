// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaguaDukiDao {
    enum Trigram {
        Heaven_Qian_1_ALM, // 1 ☰ Qian - 111 Heaven/Sky suggest 2.5%
        Lake_Dui_2_Nation, // 2 ☱ Dui - 110 Lake/Marsh  suggest 2.5% . (no more than 5% total, need compete with others who do not give; maybe a fitness loss if kindness do not begets kindness)
        Fire_Li_3_Community, //3 ☲ Li - Fire, 101 Community, Currently has Lottery, currently be like marketing
        Thunder_Zhen_4_Builders, //4 ☳ Zhen 100- Thunder, Other Creators That Are Building for Duki in Action
        Wind_Xun_5_Contributors, //5 ☴ Xun 011- Wind/Wood, Contributors
        Water_Kan_6_Investors, // 6  ☵ Kan 010- Water, investors
        Mountain_Gen_7_Maintainers, // 7 ☶ 001 Gen - Mountain, creators, #may need pay taxes
        Earth_Kun_8_Founders // 8 ☷ Kun 000 - Earth, survival and existence, sin,

    }

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
    error InvestorsFull();
    error InsufficientDistributionAmount(uint256 balance);
    error NoDistributionUnitLeft();
    error LoveAsMoneyIntoDaoRequired();
    error InvalidSignature();
    error OnlyAutomationCanCall();
    error DaoEvolutionInProgress();
    error InsufficientPayment(uint256 provided, uint256 required);
    error MustWaitBetweenEvolutions(uint256 lastEvolution, uint256 requiredWait, uint256 currentTime);
    error OnlyAnyrandCanCall();
    error OnlyMaintainerOrAutomationCanCall();
    error UnknownWillId(uint256 willId, uint256 expectedWillId);
    error NoPendingRandomnessWill();
    error RefundFailed();

    event BaguaDukiDaoBpsChanged(uint256[8] oldBpsArr, uint256[8] newBpsArr, uint256 timestamp);

    error TransferFailed(CoinFlowType t, address other, uint256 amount);

    enum CoinFlowType {
        In,
        Out
    }
}
