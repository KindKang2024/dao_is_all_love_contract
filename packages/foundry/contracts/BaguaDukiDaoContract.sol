//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
// pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./dependencies/IMinUNSRegistry.sol";
import "./libraries/IBaguaDukiDao.sol";
import "forge-std/console2.sol"; // For Foundry
// import "@chainlink/contracts/vrf/VRFConsumerBaseV2.sol";

// Useful for debugging. Remove when deploying to a live network.
import "./libraries/UnstoppableDukiDaoConstants.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@solady/utils/LibString.sol";

/**
 * A smart contract that allows changing a state variable of the contract and tracking the changes
 * It also allows the owner to withdraw the Ether in the contract
 * @author KindKang2024
 */
contract BaguaDukiDaoContract is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    UnstoppableDukiDaoConstants,
    IUnstoppableDukiDao
{
    IERC20 private stableCoin;

    uint256[8] s_dao_bps_arr;
    // calculate total unit for each trigram dynamically
    uint256[8] s_dao_bps_count_arr;

    // each
    uint256 public s_dao_bornSeconds; // the timestamp when the dao was created
    uint256 public s_dao_evolve_step; // start from 0,  monotonic increasing step=1
    uint256 public s_dao_evovle_block_num; // block number, monotonic increasing
    DaoFairDrop[8] s_dao_fair_drop_arr;

    uint256 private s_dao_claimed_amount;

    uint256[3] s_lucky_community_participants;

    uint256 s_investment_3_fee;

    mapping(address => uint256 claimedEvolveNum) s_earth_0_founders;

    mapping(address => uint256 claimedEvolveNum) s_mountain_1_maintainers;

    mapping(address => uint256 claimedEvolveNum) s_water_2_investors;

    mapping(address => uint256 claimedEvolveNum) s_wind_3_contributors; //
    mapping(address => uint256 claimedEvolveNum) s_thunder_4_duki_Builders;

    mapping(address => CommunityParticipation) s_community_5_Participants;

    mapping(address => uint256 claimedEvolveNum) s_alm_nation_6_supporters; // all people inside one country

    mapping(address => uint256 claimedEvolveNum) s_alm_world_7_dukiClaimers; // requires hold unstoppable domains owner to be a unique human being, concept now; a user can claim using multiple domains now

    // Reserved storage slots for future upgrades
    // This ensures we can add new storage variables without corrupting existing storage layout
    uint256[49] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(NetworkConfig memory config) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);

        s_investment_3_fee = 1000 * ONE_DOLLAR_BASE;
        s_dao_evolve_step = 0; // initial 0,  monotonic increasing
        s_dao_evovle_block_num = 0; // 0 means not evolve yet, when evolved, it becomes block.number;
        s_dao_bornSeconds = block.timestamp;

        stableCoin = IERC20(config.stableCoin);

        s_dao_bps_arr = [
            Initial_0_Founders_Bps,
            Initial_1_Maintainers_Bps,
            Initial_2_Investors_Bps,
            Initial_3_Contributors_Bps,
            Initial_4_Builders_Bps,
            Initial_5_Community_Bps,
            Initial_6_ALM_Nation_DukiInAction_Bps, // DUKI for all - empower all to reject evil, do good and be love
            Initial_7_ALM_World_DukiInAction_Bps // DUKI for all - empower all to reject evil, do good and be love
        ];

        // 1. Validate and set shares
        for (uint256 i = 0; i < config.creators.length; i++) {
            if (config.creators[i] == address(0)) revert ZeroAddressError();
            s_earth_0_founders[config.creators[i]] = Initial_Claim_FairDrop_Round;
        }

        s_dao_bps_count_arr[SEQ_0_Earth_Founders] = config.creators.length;

        uint256[8] memory emptyArr;
        for (uint256 i = 0; i < config.maintainers.length; i++) {
            if (config.maintainers[i] == address(0)) revert ZeroAddressError();
            s_mountain_1_maintainers[config.maintainers[i]] = Initial_Claim_FairDrop_Round;
        }
        s_dao_bps_count_arr[SEQ_1_Mountain_Maintainers] = config.maintainers.length;

        emit BaguaDukiDaoBpsChanged(emptyArr, s_dao_bps_arr, block.timestamp);
    }

    // Authorization function for contract upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        require(newImplementation != address(0), "New implementation cannot be zero address");
    }

    function totalStableCoin() external view override returns (uint256) {
        return stableCoin.balanceOf(address(this));
    }

    function stableCoinAddress() external view returns (address) {
        return address(stableCoin);
    }

    function baguaDaoUnitCountArr() external view override returns (uint256[8] memory) {
        return s_dao_bps_count_arr;
    }

    function baguaDaoFairDropArr() external view override returns (DaoFairDrop[8] memory) {
        return s_dao_fair_drop_arr;
    }

    function baguaDaoBpsArr() external view override returns (uint256[8] memory) {
        return s_dao_bps_arr;
    }

    function buaguaDaoAgg4Me(address user) external view override returns (BaguaDaoAgg memory) {
        uint256 curEvolveBlockNum = s_dao_evovle_block_num;

        bool almQualified = true;
        bool investorClaimedQualified = false;

        CommunityParticipation memory participation = s_community_5_Participants[user];

        uint256[8] memory userClaimedRoundArr = [
            s_earth_0_founders[user],
            s_mountain_1_maintainers[user],
            s_water_2_investors[user],
            s_wind_3_contributors[user],
            s_thunder_4_duki_Builders[user],
            participation.participantNo,
            s_alm_nation_6_supporters[user],
            s_alm_world_7_dukiClaimers[user]
        ];

        uint256 lotteryWinnerNumber = s_dao_fair_drop_arr[0].unitNumber;

        return BaguaDaoAgg(
            s_dao_bornSeconds,
            s_dao_claimed_amount,
            s_dao_bps_arr,
            s_dao_bps_count_arr,
            s_dao_fair_drop_arr,
            s_lucky_community_participants,
            userClaimedRoundArr,
            participation.participantNo
        );
    }

    /**
     * daoDistribution
     */
    function evolveDaoAndDivideLove(uint32 communityLuckyReminderNumber) external returns (bool, uint256) {
        // CHECKS
        uint256 balance = stableCoin.balanceOf(address(this));

        if (balance < DAO_START_EVOLVE_AMOUNT) {
            console2.log(
                "balance < DAO_START_EVOLVE_AMOUNT, skip evolveDaoThenDistribute", balance, DAO_START_EVOLVE_AMOUNT
            );
            return (false, s_dao_evovle_block_num);
        }

        uint256 distributionAmount = balance - DAO_EVOLVE_LEFT_AMOUNT;

        // s_lucky_community_participants = [communityLuckyReminderNumber, 0, 0];
        // EFFECTS
        s_dao_evolve_step += 1;
        s_dao_evovle_block_num = block.number;

        DaoFairDrop[8] memory daoFairDrops;
        //  dukiInAction
        uint256[8] memory bpsUnitNumArr = s_dao_bps_count_arr;

        // iterate over baguaDaoUnitTotals
        for (uint256 i = 0; i < 8; i++) {
            uint256 bpsAmount = (s_dao_bps_arr[i] * distributionAmount) / BPS_PRECISION;
            uint256 bpsUnitNum = bpsUnitNumArr[i];

            if (SEQ_7_DukiInAction_ALM_World == i) {
                uint256 almUnitTotalNum = bpsAmount / DukiInAction_StableCoin_Claim_Amount;
                daoFairDrops[i] = DaoFairDrop(DukiInAction_StableCoin_Claim_Amount, almUnitTotalNum, almUnitTotalNum);
            } else if (SEQ_5_Community_Participants == i) {
                if (bpsUnitNum == 0) {
                    // no one join the community , sad story
                    continue;
                }

                // lottery for community
                uint256 communityUsersCount = s_dao_bps_count_arr[SEQ_5_Community_Participants];
                uint256 reminderNum = communityUsersCount % LotteryMaxLuckyNumber; // 40
                uint256 unitTotalNum = communityUsersCount / LotteryMaxLuckyNumber; // 0

                // Initialize array for lucky participants
                uint256[3] memory luckyParticipants;

                // Calculate first possible winner number
                // ((communityLuckyReminderNumber <= reminderNum ? 1 : 0) + unitTotalNum)
                uint256 maxWinnerNum = unitTotalNum * LotteryMaxLuckyNumber + communityLuckyReminderNumber;

                // Add subsequent winner numbers (MaxLotteryParticipantNumber apart)
                uint256 luckyCount = 0;
                for (uint256 j = 0; j < 3; j++) {
                    uint256 nextWinnerNum = maxWinnerNum - (j * LotteryMaxLuckyNumber);
                    if (nextWinnerNum <= 0) {
                        luckyParticipants[luckyCount] = 0;
                        continue;
                    }
                    luckyParticipants[luckyCount] = nextWinnerNum;
                    luckyCount++;
                }

                uint256 unitAmount = bpsAmount / luckyCount; // luckyCount > 0
                daoFairDrops[i] = DaoFairDrop(unitAmount, luckyCount, unitTotalNum);
                s_lucky_community_participants = luckyParticipants;
            } else {
                if (bpsUnitNum == 0) {
                    continue;
                }
                uint256 unitAmount = bpsAmount / bpsUnitNum;
                daoFairDrops[i] = DaoFairDrop(unitAmount, bpsUnitNum, bpsUnitNum);
            }
        }

        // Set the values in batch
        for (uint256 i = 0; i < daoFairDrops.length; i++) {
            s_dao_fair_drop_arr[i] = daoFairDrops[i];
        }

        emit DukiDaoEvolution(s_dao_evovle_block_num, s_lucky_community_participants, daoFairDrops, block.timestamp);
        return (true, s_dao_evolve_step);
    }

    /**
     *
     */
    function payLoveIntoDao(
        string calldata willMessage,
        string calldata willSignature,
        uint256 willDivinationResult,
        uint256 loveAsMoneyAmount
    ) external {
        // CHECKS
        if (msg.sender == address(0)) {
            revert ZeroAddressError();
        }

        // money must amount must > 0
        if (loveAsMoneyAmount <= 0) {
            revert LoveAsMoneyIntoDaoRequired();
        }
        // check the signature using erc_recover
        // address signer = ecrecover(willMessage, willSignature, willDivinationResult);
        // if (signer != msg.sender) {
        //     revert InvalidSignature();
        // }
        // EFFECTS
        // user first join the community
        if (s_community_5_Participants[msg.sender].participantNo <= 0) {
            s_dao_bps_count_arr[SEQ_5_Community_Participants] += 1;
            s_community_5_Participants[msg.sender] =
                CommunityParticipation(block.number, s_dao_bps_count_arr[SEQ_5_Community_Participants]);
        }
        // FIXME: emit event
        // emit CommunityLotteryEntry(
        //   msg.sender, bonusEntry, s_baguaDaoUnitCountArr[SEQ_3_Fire_Community]
        // );
        commonDeductFee(InteractType.In_To_Divine, loveAsMoneyAmount);
    }

    function isStructExist(CommunityParticipation memory qualification) internal pure returns (bool) {
        return qualification.participantNo > 0;
    }

    /**
     * a way to support, at least 10% of the total project revenue will be shared with the investors
     */
    function payToInvest() external {
        // CHECKS
        if (s_dao_bps_count_arr[SEQ_2_Water_Investors] > MaxInvestorsTotal) {
            revert InvestorsFull();
        }

        if (s_water_2_investors[msg.sender] >= Initial_Evolve_Base_Num) {
            revert AlreadyInvested();
        }

        // EFFECTS
        s_dao_bps_count_arr[SEQ_2_Water_Investors] += 1;
        s_water_2_investors[msg.sender] = block.number;

        // INTERACTIONS
        commonDeductFee(InteractType.In_To_Invest, BASIC_INVEST_AMOUNT);

        // FIXME: emit event
        // emit InvestorAdded(msg.sender, s_dao_bps_count_arr[SEQ_2_Water_Investors]);
    }

    /**
     *
     */
    function claim1Love_WorldDukiInActionFairDrop() external {
        // CHECKS

        uint256 domainClaimedEvolveNum = s_alm_world_7_dukiClaimers[msg.sender];
        if (domainClaimedEvolveNum >= s_dao_evovle_block_num) {
            console2.log(
                "claim1_AlmDukiInActionFairDrop already claimed",
                msg.sender,
                domainClaimedEvolveNum,
                s_dao_evovle_block_num
            );
            revert ClaimedCurrentRoundAlreadyError();
        }

        DaoFairDrop storage fairDrop = s_dao_fair_drop_arr[SEQ_7_DukiInAction_ALM_World];

        if (fairDrop.unitNumber <= 0) {
            console2.log("claim1_AlmDukiInActionFairDrop no distribution unit left", msg.sender);
            revert NoDistributionUnitLeft();
        }

        // EFFECTS
        s_alm_world_7_dukiClaimers[msg.sender] = s_dao_evovle_block_num;
        fairDrop.unitNumber -= 1;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }
        //  address user;
        // InteractType interactType;
        // uint256 daoEvolveNum;
        // uint256 amount;
        // uint256 unitNumber;

        emit DukiInActionEvent(
            msg.sender,
            InteractType.Out_Claim_As_Duki4World,
            s_dao_evolve_step,
            fairDrop.unitAmount,
            fairDrop.unitNumber,
            block.timestamp
        );
    }

    function claim2Love_NationDukiInActionFairDrop() external {
        revert NotSupported("maybe we need government to back zkp human proof for all this duki in action");
    }

    function claim3Love_CommunityLotteryFairDrop() external {
        // CHECKS
        CommunityParticipation memory participation = s_community_5_Participants[msg.sender];

        if (participation.participantNo == 0) {
            console2.log("claim3_CommunityLotteryDrop not in lottery community", msg.sender);
            revert NotCommunityParticipant();
        }

        uint256[3] memory luckyParticipantNoList = s_lucky_community_participants;

        if (
            participation.participantNo != luckyParticipantNoList[0]
                || participation.participantNo != luckyParticipantNoList[1]
                || participation.participantNo != luckyParticipantNoList[2]
        ) {
            // console2.log(
            //     "claim3_CommunityLotteryDrop not winner",
            //     msg.sender,
            //     luckyParticipantNoList,
            //     participation.participantNo
            // );
            revert NotCommunityLotteryWinner();
        }

        if (participation.claimedRound == s_dao_evovle_block_num) {
            console2.log(
                "claim3_CommunityLotteryDrop already claimed",
                msg.sender,
                participation.claimedRound,
                s_dao_evovle_block_num
            );
            revert ClaimedCurrentRoundAlreadyError();
        }
        DaoFairDrop memory fairDrop = s_dao_fair_drop_arr[SEQ_5_Community_Participants];
        // EFFECTS
        // dropSummary.unitNumber -= 1;
        // participation.claimedRound = s_dao_evovle_block_num;
        s_dao_fair_drop_arr[SEQ_5_Community_Participants].unitNumber -= 1;
        s_community_5_Participants[msg.sender].claimedRound = s_dao_evovle_block_num;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }
        console2.log("claim3_CommunityLotteryDrop", msg.sender, fairDrop.unitAmount);

        emit DukiInActionEvent(
            msg.sender,
            InteractType.Out_Claim_As_CommunityLottery,
            s_dao_evovle_block_num,
            fairDrop.unitAmount,
            1,
            block.timestamp
        );
    }

    function claim4Love_BuilderFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Builder, SEQ_4_Thunder_DukiBuilders, s_thunder_4_duki_Builders);
    }

    function claim5Love_ContributorFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Contributor, SEQ_3_Wind_Contributors, s_wind_3_contributors);
    }

    function claim6Love_InvestorFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Investor, SEQ_2_Water_Investors, s_water_2_investors);
    }

    function claim7Love_MaintainerFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Maintainer, SEQ_1_Mountain_Maintainers, s_mountain_1_maintainers);
    }

    function claim8Love_FounderFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Founder, SEQ_0_Earth_Founders, s_earth_0_founders);
    }

    function common_claim(
        InteractType interactType,
        uint256 seq,
        mapping(address => uint256 claimedEvolveNum) storage claimMap
    ) internal {
        if (msg.sender == address(0)) {
            revert ZeroAddressError();
        }

        uint256 claimedRound = claimMap[msg.sender];

        if (claimedRound < Initial_Evolve_Base_Num) {
            console2.log("common_claim is not qualified", msg.sender, claimedRound);
            revert NotQualifiedForClaim(interactType);
        }

        if (claimedRound == s_dao_evovle_block_num) {
            console2.log("common_claim already claimed", msg.sender, claimedRound, s_dao_evovle_block_num);
            revert ClaimedCurrentRoundAlreadyError();
        }

        if (claimedRound > s_dao_evovle_block_num) {
            console2.log(
                "common_claim joined after current dao distribution, not qualified",
                msg.sender,
                claimedRound,
                s_dao_evovle_block_num
            );
            revert JoinedAfterCurrentDaoDistribution();
        }

        DaoFairDrop storage fairDrop = s_dao_fair_drop_arr[seq];

        // EFFECTS
        fairDrop.unitNumber -= 1;
        claimMap[msg.sender] = s_dao_evovle_block_num;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        emit DukiInActionEvent(
            msg.sender, interactType, s_dao_evovle_block_num, fairDrop.unitAmount, 1, block.timestamp
        );
    }

    function commonDeductFee(InteractType interactType, uint256 requiredMoney) internal {
        uint256 allowanceMoney = stableCoin.allowance(msg.sender, address(this));
        if (allowanceMoney < requiredMoney) {
            console2.log("InsufficientAllowance:allowanceMoney < requiredMoney", allowanceMoney, requiredMoney);
            revert InsufficientAllowance(interactType, msg.sender, requiredMoney);
        }

        bool success = stableCoin.transferFrom(msg.sender, address(this), requiredMoney);

        console2.log("CoinReceived, requiredMoney from", success, requiredMoney);

        if (success) {
            emit DukiInActionEvent(msg.sender, interactType, s_dao_evovle_block_num, requiredMoney, 1, block.timestamp);
        } else {
            console2.log("TransferFailed:TransferFailed");
            revert TransferFailed(CoinFlowType.In, msg.sender, requiredMoney);
        }
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable { }

    // function claim5_ContributorFairDrop() external override {}
}
