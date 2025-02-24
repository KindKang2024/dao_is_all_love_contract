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
    IMinUNSRegistry private unsRegistry;

    IERC20 private stableCoin;

    uint256[9] s_baguaDaoBpsArr;

    // calculate total unit for each trigram dynamically
    uint256[9] s_baguaDaoUnitCountArr;

    // each
    uint256 public s_daoEvolveNum; // start from 0,  monotonic increasing step=1

    uint256 public s_bornSeconds; // the timestamp when the dao was created

    uint256 public s_daoEvolveBlockNum; // block number, monotonic increasing
    uint256 public s_lotteryWinnerNumber; // the number of the lottery winner

    DaoFairDrop[9] s_baguaDaoFairDropArr;

    uint256 private s_claimed_amount;

    // public love users
    uint256 public s_subscription_yearly_fee; // 12 coin per year, may change later
    uint256 public s_community_lottery_3_entry_fee;
    uint256 public s_investment_6_fee;

    // mapping(address => uint256 claimedEvolveNum) public s_alm_1_dukiClaimers; // requires hold unstoppable domains owner to be a unique human being, concept now; a user can claim using multiple domains now
    mapping(uint256 => uint256 claimedEvolveNum) public s_alm_1_dukiClaimerDomains; // domains

    // uint256 private s_lotteryParticipantTotal;

    // mapping(address => uint256 claimedEvolveNum) public s_nation_supporters; // all people inside one country

    mapping(address => LotteryQualification) s_community_lottery_3_Participants;

    mapping(address => uint256 claimedEvolveNum) s_unstoppable_4_duki_Builders;

    mapping(address => uint256 claimedEvolveNum) s_wind_5_contributors;

    // s_baguaDaoUnitCountArr records fair drop count, community are participants including subscribers,investors,maintainers except duki participants without other interactions
    uint256 public s_unstoppableInvestorsCount; // < MaxLifetimeSupportersTotal limited lifetime uns user subscription

    uint256 public s_unstoppableSubscriberCount; // normal uns user subscription, without limit

    mapping(address => uint256 claimedEvolveNum) s_8_creators;

    mapping(address => uint256 claimedEvolveNum) s_survival_7_Maintainers;

    mapping(uint256 => uint256 claimedEvolveNum) s_6_domain_investors;

    mapping(address => uint256 claimedEvolveNum) s_wind_xun5_contributors; //

    //unstoppable domain subscription
    mapping(uint256 => uint256) s_unstoppableSubscriptions; // normal uns tokenId, uint64.max means investment ,which is lifetime

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

        s_subscription_yearly_fee = Initial_Subscription_Yearly_Fee;
        s_community_lottery_3_entry_fee = Initial_Lottery_Entry_Fee;
        s_investment_6_fee = Initial_Investment_Fee;
        s_daoEvolveNum = 0; // initial 0,  monotonic increasing
        s_daoEvolveBlockNum = 0; // 0 means not evolve yet, when evolved, it becomes block.number;
        s_bornSeconds = block.timestamp;

        stableCoin = IERC20(config.stableCoin);

        s_baguaDaoBpsArr = [
            BPS_PRECISION, // AllLivesMatter.World
            Initial_1_MIN_DukiInAction_Bps, // DUKI for all - empower all to reject evil, do good and be love
            Initial_Zero,
            Initial_2_Community_Lottery_Bps, // All lives matter need all lives matter, bootstrap loop; may decress to 10% time gos on
            Initial_Zero, //   builders
            Initial_Zero, //   maybe setup a account for @kinteh_mod8017
            Initial_6_Investors_Bps, // be love - reject evil, do good, needs power
            Initial_7_SurvivalMaintainers_Bps, // without survival, there is no existence, no story, no life, no death, no love, no dao related to creation
            Initial_8_Creators_Bps // dao is love -- love be ye way to create sth from void
        ];

        // 1. Validate and set shares
        for (uint256 i = 0; i < config.creators.length; i++) {
            if (config.creators[i] == address(0)) revert ZeroAddressError();
            s_8_creators[config.creators[i]] = Initial_Claim_FairDrop_Round;
        }

        s_baguaDaoUnitCountArr[SEQ_8_Earth_Creators] = config.creators.length;

        uint256[9] memory emptyArr;

        for (uint256 i = 0; i < config.maintainers.length; i++) {
            if (config.maintainers[i] == address(0)) revert ZeroAddressError();
            s_survival_7_Maintainers[config.maintainers[i]] = Initial_Claim_FairDrop_Round;
        }

        s_baguaDaoUnitCountArr[SEQ_7_Mountain_Maintainers] = config.maintainers.length;

        emit BaguaDukiDaoBpsChanged(emptyArr, s_baguaDaoBpsArr, block.timestamp);
    }

    // Authorization function for contract upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        require(newImplementation != address(0), "New implementation cannot be zero address");
    }

    function updateBaguaDaoBps(uint256[9] calldata newDaoBpsArr) public {
        uint256 total = 0;
        for (uint256 i = 1; i <= 9; i++) {
            total += newDaoBpsArr[i];
        }
        if (total != BPS_PRECISION && newDaoBpsArr[0] != total) {
            revert BpsSumError();
        }

        // guard from change it too small
        if (newDaoBpsArr[SEQ_1_Heaven_ALM_DukiInAction] < MIN_DukiInAction_Bps) {
            revert BpsTooSmallViolationError();
        }

        if (newDaoBpsArr[SEQ_3_Fire_Community] < Min_Community_Lottery_Bps) {
            revert BpsTooSmallViolationError();
        }

        if (newDaoBpsArr[SEQ_6_Water_Investors] < Min_Investors_Bps) {
            revert BpsTooSmallViolationError();
        }

        if (newDaoBpsArr[SEQ_7_Mountain_Maintainers] < Min_SurvivalMaintainers_Bps) {
            revert BpsTooSmallViolationError();
        }

        // guard from change it too large
        if (newDaoBpsArr[SEQ_8_Earth_Creators] > Max_Creators_Bps) {
            revert BpsTooLargeViolationError();
        }

        // protect investors , lifetime subscription and dukiInAction , maybe just trust me for the present
        uint256[9] memory oldBaguaBpsShares = newDaoBpsArr;
        s_baguaDaoBpsArr = newDaoBpsArr;
        // Emit events
        emit BaguaDukiDaoBpsChanged(oldBaguaBpsShares, s_baguaDaoBpsArr, block.timestamp);
    }

    modifier mustBeUnstoppableDomain(string memory label) {
        if (LibString.startsWith(label, UNS_TEST_DOMAIN)) {
            revert UnsTestDomainError();
        }
        if (LibString.contains(label, ".")) {
            revert UnsSubDomainForbidden();
        }
        _;
    }

    function totalStableCoin() external view override returns (uint256) {
        return stableCoin.balanceOf(address(this));
    }

    function stableCoinAddress() external view returns (address) {
        return address(stableCoin);
    }

    function uniRegistryAddress() external view returns (address) {
        return address(unsRegistry);
    }

    function lotteryQualification(address user) external view override returns (LotteryQualification memory) {
        return s_community_lottery_3_Participants[user];
    }

    function baguaDaoUnitCountArr() external view override returns (uint256[9] memory) {
        return s_baguaDaoUnitCountArr;
    }

    function baguaDaoFairDropArr() external view override returns (DaoFairDrop[9] memory) {
        return s_baguaDaoFairDropArr;
    }

    function baguaDaoBpsArr() external view override returns (uint256[9] memory) {
        return s_baguaDaoBpsArr;
    }

    function expireSecondsOfSubscription(string calldata uns_domain) external view returns (uint256) {
        uint256 uns_domain_token = uns_domain_to_token(uns_domain);
        return s_unstoppableSubscriptions[uns_domain_token];
    }

    function buaguaDaoAgg4Me(address user, string calldata uns_domain)
        external
        view
        override
        returns (BaguaDaoAgg memory)
    {
        uint256 curEvolveBlockNum = s_daoEvolveBlockNum;

        // if uns_domain 's length = 0, it means the caller is not an unstoppable domain owner
        bool almQualified = true;
        bool unsDomainIsEmpty = bytes(uns_domain).length == 0;
        bool investorClaimedQualified = false;
        uint256 subscriptionExpireSeconds = 0;

        uint256[9] memory claimedRoundArr;
        claimedRoundArr[0] = s_daoEvolveBlockNum;

        if (!unsDomainIsEmpty) {
            uint256 uns_domain_token = uns_domain_to_token(uns_domain);
            subscriptionExpireSeconds = s_unstoppableSubscriptions[uns_domain_token];
            // almQualified = almClaimedRound < curEvolveBlockNum;
            claimedRoundArr[1] = s_alm_1_dukiClaimerDomains[uns_domain_token];
            claimedRoundArr[5] = s_6_domain_investors[uns_domain_token];
        }

        LotteryQualification memory qualification = s_community_lottery_3_Participants[user];
        claimedRoundArr[3] = qualification.claimedRound;

        uint256 lotteryWinnerNumber = s_baguaDaoFairDropArr[0].unitNumber;

        if (user != address(0)) {
            claimedRoundArr[4] = s_unstoppable_4_duki_Builders[user];
            claimedRoundArr[5] = s_wind_5_contributors[user];
            claimedRoundArr[7] = s_survival_7_Maintainers[user];
            claimedRoundArr[8] = s_8_creators[user];
        }

        return BaguaDaoAgg(
            s_bornSeconds,
            subscriptionExpireSeconds,
            s_lotteryWinnerNumber,
            qualification.participantNum,
            s_claimed_amount,
            claimedRoundArr,
            s_baguaDaoBpsArr,
            s_baguaDaoUnitCountArr,
            s_baguaDaoFairDropArr
        );
    }

    /**
     * daoDistribution
     */
    function evolveDaoThenDistribute(uint32 lotteryWinnerNumber) external returns (bool, uint256) {
        // CHECKS
        uint256 balance = stableCoin.balanceOf(address(this));

        if (balance < DAO_START_EVOLVE_AMOUNT) {
            console2.log(
                "balance < DAO_START_EVOLVE_AMOUNT, skip evolveDaoThenDistribute", balance, DAO_START_EVOLVE_AMOUNT
            );
            return (false, s_daoEvolveBlockNum);
        }

        uint256 distributionAmount = balance - DAO_EVOLVE_LEFT_AMOUNT;

        // EFFECTS
        s_daoEvolveNum += 1;
        s_daoEvolveBlockNum = block.number;
        s_lotteryWinnerNumber = lotteryWinnerNumber;

        DaoFairDrop[9] memory daoFairDrops;
        daoFairDrops[0] = DaoFairDrop(distributionAmount, s_daoEvolveNum, block.number);

        //  dukiInAction
        uint256[9] memory bpsUnitNumArr = s_baguaDaoUnitCountArr;

        // iterate over baguaDaoUnitTotals
        for (uint256 i = 1; i < s_baguaDaoFairDropArr.length; i++) {
            uint256 bpsAmount = (s_baguaDaoBpsArr[i] * distributionAmount) / BPS_PRECISION;

            uint256 bpsUnitNum = bpsUnitNumArr[i];

            if (SEQ_1_Heaven_ALM_DukiInAction == i) {
                uint256 almUnitTotalNum = bpsUnitNum + Alm_DukiInAction_StepIncr_Num;
                uint256 almUnitAmount = bpsAmount / almUnitTotalNum;
                if (almUnitAmount < Min_StableCoin_Claim_Amount) {
                    almUnitAmount = Min_StableCoin_Claim_Amount;
                    almUnitTotalNum = bpsAmount / almUnitAmount;
                }
                daoFairDrops[i] = DaoFairDrop(almUnitAmount, almUnitTotalNum, almUnitTotalNum);
            } else if (SEQ_3_Fire_Community == i) {
                if (bpsUnitNum == 0) {
                    continue;
                }

                // lottery for community
                uint256 lotteryUsersNum = s_baguaDaoUnitCountArr[SEQ_3_Fire_Community];
                uint256 reminderNum = lotteryUsersNum % MaxLotteryParticipantNumber;
                uint256 unitTotalNum =
                    (lotteryUsersNum / MaxLotteryParticipantNumber) + (lotteryWinnerNumber <= reminderNum ? 1 : 0);
                if (unitTotalNum > Max_Lottery_Winner_Per_Round) {
                    unitTotalNum = Max_Lottery_Winner_Per_Round;
                }
                uint256 unitAmount = bpsAmount / unitTotalNum;
                daoFairDrops[i] = DaoFairDrop(unitAmount, unitTotalNum, unitTotalNum);
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
            s_baguaDaoFairDropArr[i] = daoFairDrops[i];
        }

        emit DukiDaoEvolution(s_daoEvolveBlockNum, lotteryWinnerNumber, daoFairDrops, block.timestamp);
        return (true, s_daoEvolveNum);
    }

    function uns_domain_to_token(string calldata uns_domain) internal view returns (uint256) {
        string[] memory uns_domain_labels = new string[](2);
        uns_domain_labels[0] = uns_domain;
        uns_domain_labels[1] = UNS_TLD;
        return unsRegistry.namehash(uns_domain_labels);
    }

    function validateAndConvertUnsDomain(string calldata uns_domain, address uns_domain_owner)
        internal
        view
        mustBeUnstoppableDomain(uns_domain)
        returns (uint256)
    {
        uint256 uns_domain_token = uns_domain_to_token(uns_domain);
        address token_owner = unsRegistry.ownerOf(uns_domain_token);
        if (token_owner != uns_domain_owner) {
            console2.log("msgSender,token_owner is ", uns_domain_owner, token_owner);
            revert NotUnsDomainOwnerError();
        }

        return uns_domain_token;
    }

    /**
     *
     * @param uns_domain unstoppable domain name, e.g. "kindkang.unstoppable", use kindkang only
     * @param _subYears  the number of years to subscribe ; when value = 0, it means invest lifetime subscription
     */
    function payToSubscribe(string calldata uns_domain, uint32 _subYears) external {
        // Interactions
        // coin transfer
        // function allowance(address owner, address spender) external view returns (uint256);
        // CHECKS
        if (msg.sender == address(0)) {
            revert ZeroAddressError();
        }
        if (_subYears < 1) {
            revert SubscriptionYearsInvalid();
        }

        uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);
        // check if the subscription already exists
        if (s_unstoppableSubscriptions[uns_domain_token] != 0) {
            console2.log("uns_domain_token exists -> SubscriptionExistsError");
            revert SubscriptionExistsError();
        }

        // uint256 subscription_required_coin = Lifetime_Subscription_Represent_Value;
        // uint256 expireTimeSeconds = LIFE_TIME_EXPIRE_SECONDS;
        uint256 subscription_required_coin = _subYears * s_subscription_yearly_fee;
        console2.log("sub fees=yearly_fee*years = ", s_subscription_yearly_fee, _subYears, subscription_required_coin);
        uint256 expireTimeSeconds = block.timestamp + (_subYears * 365 days);

        // if (isLifetimeSubscription) {
        //   expireTime = LIFE_TIME_EXPIRE_SECONDS;
        //   // EFFECTS
        //   s_unstoppableSubscriptions[uns_domain_token] = expireTimeSeconds;
        //   s_unstoppableInvestorsCount += 1;
        // } else {
        //   s_unstoppableSubscriberCount += 1;
        // }

        // EFFECTS
        s_unstoppableSubscriberCount += 1;
        s_unstoppableSubscriptions[uns_domain_token] = expireTimeSeconds;

        addToCommunityForLottery();

        commonDeductFee(InteractType.In_To_Create_Subscription, subscription_required_coin, _subYears, uns_domain);
    }

    function isStructExist(LotteryQualification memory qualification) internal pure returns (bool) {
        return qualification.participantNum > 0;
    }

    function payToExtend(string calldata uns_domain, uint32 _extendYears)
        external
        mustBeUnstoppableDomain(uns_domain)
    {
        if (_extendYears < 1) {
            revert SubscriptionYearsInvalid();
        }

        uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

        uint256 expireSeconds = s_unstoppableSubscriptions[uns_domain_token];

        if (expireSeconds == 0) {
            revert SubscriptionNotExist();
        }

        if (expireSeconds == LIFE_TIME_EXPIRE_SECONDS) {
            revert NoNeedExtendLifetimeSubscription();
        }

        if (expireSeconds < block.timestamp) {
            expireSeconds = block.timestamp;
        }

        // Add subscription time
        uint256 newExpireSeconds = expireSeconds + (_extendYears * 365 days);

        // Store the new expiration
        s_unstoppableSubscriptions[uns_domain_token] = newExpireSeconds;

        uint256 subscription_required_coin = _extendYears * s_subscription_yearly_fee;

        // uint256 allowanceMoney = stableCoin.allowance(msg.sender, address(this));
        // if (allowanceMoney < subscription_required_coin) {
        //   revert InsufficientAllowance(
        //     CoinReceiveType.Extend_Subscription,
        //     msg.sender,
        //     subscription_required_coin
        //   );
        // }

        s_unstoppableSubscriptions[uns_domain_token] = newExpireSeconds;

        commonDeductFee(InteractType.In_To_Extend_Subscription, subscription_required_coin, _extendYears, uns_domain);
    }

    function addToCommunityForLottery() internal returns (bool) {
        if (s_community_lottery_3_Participants[msg.sender].participantNum > 0) {
            return false;
        }

        s_baguaDaoUnitCountArr[SEQ_3_Fire_Community] += 1;
        s_community_lottery_3_Participants[msg.sender] =
            LotteryQualification(block.number, s_baguaDaoUnitCountArr[SEQ_3_Fire_Community]);
        // emit CommunityLotteryEntry(
        //   msg.sender, bonusEntry, s_baguaDaoUnitCountArr[SEQ_3_Fire_Community]
        // );
        return true;
    }

    function payToJoinCommunityAndLottery() external {
        bool added = addToCommunityForLottery();
        if (!added) {
            revert AlreadyEnteredLottery();
        }
        commonDeductFee(InteractType.In_To_Community_Lottery, s_community_lottery_3_entry_fee, 1, "");
    }

    /**
     * a way to support, at least 10% of the total project revenue will be shared with the investors
     */
    function payToInvestUnsInLimo(string calldata uns_domain) external override mustBeUnstoppableDomain(uns_domain) {
        uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

        // CHECKS
        if (s_baguaDaoUnitCountArr[SEQ_6_Water_Investors] > MaxInvestorsTotal) {
            revert InvestorsFull();
        }

        if (s_6_domain_investors[uns_domain_token] >= Initial_Evolve_Base_Num) {
            revert AlreadyInvested();
        }

        // EFFECTS
        s_baguaDaoUnitCountArr[SEQ_6_Water_Investors] += 1;
        s_6_domain_investors[uns_domain_token] = block.number;

        // @dev use could be an subscriber before, now upgrade becomes an investor,
        // . but no money back for previous subscription , lottery qualification still keeps
        s_unstoppableSubscriptions[uns_domain_token] = LIFE_TIME_EXPIRE_SECONDS;

        // INTERACTIONS
        commonDeductFee(InteractType.In_To_Invest_Unstoppable_Domain, s_investment_6_fee, 1, uns_domain);

        // emit InvestorAdded(
        //   msg.sender, s_baguaDaoUnitCountArr[SEQ_6_Water_Investors]
        // );
    }

    /**
     *
     * @param uns_domain the unstoppable domain name, e.g. "kindkang.unstoppable", use kindkang only
     */
    function claim1_AlmDukiInActionFairDrop(string calldata uns_domain) external mustBeUnstoppableDomain(uns_domain) {
        // CHECKS

        uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

        uint256 domainClaimedEvolveNum = s_alm_1_dukiClaimerDomains[uns_domain_token];
        if (domainClaimedEvolveNum >= s_daoEvolveBlockNum) {
            console2.log(
                "claim1_AlmDukiInActionFairDrop already claimed",
                msg.sender,
                domainClaimedEvolveNum,
                s_daoEvolveBlockNum
            );
            revert ClaimedCurrentRoundAlreadyError();
        }

        DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[SEQ_1_Heaven_ALM_DukiInAction];

        if (fairDrop.unitNumber <= 0) {
            console2.log("claim1_AlmDukiInActionFairDrop no distribution unit left", msg.sender);
            revert NoDistributionUnitLeft();
        }

        // EFFECTS
        s_alm_1_dukiClaimerDomains[uns_domain_token] = s_daoEvolveBlockNum;
        fairDrop.unitNumber -= 1;
        s_baguaDaoUnitCountArr[SEQ_1_Heaven_ALM_DukiInAction] += 1; // no use ,just for stats

        s_claimed_amount += fairDrop.unitAmount;
        // INTERACTIONS
        bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        emit UnstoppableEvent(
            msg.sender,
            s_daoEvolveNum,
            InteractType.Out_Claim1_As_Duki4World,
            fairDrop.unitAmount,
            fairDrop.unitNumber,
            uns_domain,
            block.timestamp
        );
    }

    /**
     */
    function claim3_CommunityLotteryDrop() external {
        // CHECKS
        LotteryQualification storage qualification = s_community_lottery_3_Participants[msg.sender];

        if (qualification.participantNum == 0) {
            console2.log("claim3_CommunityLotteryDrop not in lottery community", msg.sender);
            revert NotInLottery();
        }
        DaoFairDrop memory dropSummary = s_baguaDaoFairDropArr[SEQ_0_FAIR_DROP_SUMMARY];
        uint256 winnerNumber = dropSummary.unitNumber;
        uint256 participantWinNumber = qualification.participantNum % MaxLotteryParticipantNumber;

        if (winnerNumber != participantWinNumber) {
            console2.log("claim3_CommunityLotteryDrop not winner", msg.sender, winnerNumber, participantWinNumber);
            revert NotLotteryWinner();
        }

        if (qualification.claimedRound == s_daoEvolveBlockNum) {
            console2.log(
                "claim3_CommunityLotteryDrop already claimed",
                msg.sender,
                qualification.claimedRound,
                s_daoEvolveBlockNum
            );
            revert ClaimedCurrentRoundAlreadyError();
        }

        DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[SEQ_3_Fire_Community];
        if (fairDrop.unitNumber == 0) {
            revert NoDistributionUnitLeft();
        }

        // EFFECTS
        fairDrop.unitNumber -= 1;
        qualification.claimedRound = s_daoEvolveBlockNum;
        s_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }
        console2.log("claim3_CommunityLotteryDrop", msg.sender, fairDrop.unitAmount);

        emit UnstoppableEvent(
            msg.sender,
            s_daoEvolveBlockNum,
            InteractType.Out_Claim3_As_CommunityStar,
            fairDrop.unitAmount,
            1,
            "",
            block.timestamp
        );
    }

    function claim4_BuilderFairDrop() external {
        common_claim(InteractType.Out_Claim4_As_Builder, SEQ_4_Thunder_Builders, s_unstoppable_4_duki_Builders);
    }

    function claim5_ContributorFairDrop() external {
        common_claim(InteractType.Out_Claim5_As_Contributor, SEQ_5_Wind_Contributors, s_wind_5_contributors);
    }

    function claim6_UnsInvestorFairDrop(string calldata uns_domain) external mustBeUnstoppableDomain(uns_domain) {
        uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

        uint256 claimedRound = s_6_domain_investors[uns_domain_token];

        if (claimedRound < Initial_Evolve_Base_Num) {
            console2.log("claim6_UnsInvestorFairDrop is not investor", msg.sender);
            revert ClaimDoNotHaveRole(Trigram.Water_Kan_6_Investors);
        }

        if (claimedRound >= s_daoEvolveBlockNum) {
            console2.log("claim6_UnsInvestorFairDrop already claimed", msg.sender, claimedRound, s_daoEvolveBlockNum);
            revert ClaimedCurrentRoundAlreadyError();
        }

        // EFFECTS
        DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[SEQ_6_Water_Investors];
        fairDrop.unitNumber -= 1;
        s_6_domain_investors[uns_domain_token] = s_daoEvolveBlockNum;
        s_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        console2.log("claim6_UnsInvestorFairDrop", msg.sender, fairDrop.unitAmount, fairDrop.unitNumber);

        emit UnstoppableEvent(
            msg.sender,
            s_daoEvolveBlockNum,
            InteractType.Out_Claim6_As_Investor,
            fairDrop.unitAmount,
            1,
            "",
            block.timestamp
        );
    }

    function claim7_MaintainerFairDrop() external {
        common_claim(InteractType.Out_Claim7_As_Maintainer, SEQ_7_Mountain_Maintainers, s_survival_7_Maintainers);
    }

    function claim8_CreatorFairDrop() external {
        common_claim(InteractType.Out_Claim8_As_Creator, SEQ_8_Earth_Creators, s_8_creators);
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

        if (claimedRound == s_daoEvolveBlockNum) {
            console2.log("common_claim already claimed", msg.sender, claimedRound, s_daoEvolveBlockNum);
            revert ClaimedCurrentRoundAlreadyError();
        }

        if (claimedRound > s_daoEvolveBlockNum) {
            console2.log(
                "common_claim joined after current dao distribution, not qualified",
                msg.sender,
                claimedRound,
                s_daoEvolveBlockNum
            );
            revert JoinedAfterCurrentDaoDistribution();
        }

        DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[seq];

        // EFFECTS
        fairDrop.unitNumber -= 1;
        claimMap[msg.sender] = s_daoEvolveBlockNum;
        s_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        emit UnstoppableEvent(
            msg.sender, s_daoEvolveBlockNum, interactType, fairDrop.unitAmount, 1, "", block.timestamp
        );
    }

    function commonDeductFee(InteractType interactType, uint256 requiredMoney, uint256 units, string memory uns_domain)
        internal
    {
        uint256 allowanceMoney = stableCoin.allowance(msg.sender, address(this));
        if (allowanceMoney < requiredMoney) {
            console2.log("InsufficientAllowance:allowanceMoney < requiredMoney", allowanceMoney, requiredMoney);
            revert InsufficientAllowance(interactType, msg.sender, requiredMoney);
        }

        bool success = stableCoin.transferFrom(msg.sender, address(this), requiredMoney);

        console2.log("CoinReceived, requiredMoney from", success, requiredMoney, units);

        if (success) {
            emit UnstoppableEvent(
                msg.sender, s_daoEvolveBlockNum, interactType, requiredMoney, units, uns_domain, block.timestamp
            );
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
