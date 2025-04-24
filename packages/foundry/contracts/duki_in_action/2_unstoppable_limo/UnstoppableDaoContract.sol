// //SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;
// // pragma solidity 0.8.24;

// // import "@chainlink/contracts/vrf/VRFConsumerBaseV2.sol";

// // Useful for debugging. Remove when deploying to a live network.
// import "@/dependencies/IMinUNSRegistry.sol";
// import "@/libraries/DukiDaoConstants.sol";
// import "@/libraries/DukiDaoTypes.sol";
// import "@forge-std/console2.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts/interfaces/IERC20.sol";
// import "@solady/utils/LibString.sol";
// import { IUnstoppableBaguaDao } from "./IUnstoppableBaguaDao.sol";

// /**
//  * A smart contract that allows changing a state variable of the contract and tracking the changes
//  * It also allows the owner to withdraw the Ether in the contract
//  * @author KindKang2024
//  */
// contract UnstoppableDaoContract is Initializable, UUPSUpgradeable, OwnableUpgradeable, IUnstoppableBaguaDao {
//     string constant UNS_TEST_DOMAIN = "uns-devtest-";
//     string constant UNS_TLD = "unstoppable";
//     uint256 constant Initial_Subscription_Yearly_Fee = 8 * DukiDaoConstants.ONE_DOLLAR_BASE;

//     //    IMinUNSRegistry private unsRegistry;
//     address public s_unsRegistry;

//     address public s_stableCoin;

//     uint256[8] s_baguaDaoBpsArr;

//     // calculate total unit for each trigram dynamically
//     uint256[8] s_baguaDaoUnitCountArr;

//     // each
//     uint256 public s_daoEvolveNum; // start from 0,  monotonic increasing step=1

//     uint256 public s_bornSeconds; // the timestamp when the dao was created

//     uint256 public s_daoEvolveBlockNum; // block number, monotonic increasing
//     uint256 public s_lotteryWinnerNumber; // the number of the lottery winner

//     DukiDaoTypes.DaoFairDrop[8] s_baguaDaoFairDropArr;

//     uint256 private s_claimed_amount;

//     // public love users
//     uint256 public s_subscription_yearly_fee; // 12 coin per year, may change later
//     uint256 public s_community_lottery_5_entry_fee;
//     uint256 public s_investment_3_fee;
//     // mapping(address => uint256 claimedEvolveNum) public s_alm_1_dukiClaimers; // requires hold unstoppable domains owner to be a unique human being, concept now; a user can claim using multiple domains now
//     mapping(uint256 => uint256 claimedEvolveNum) public s_alm_7_dukiClaimerDomains; // domains

//     // uint256 private s_lotteryParticipantTotal;

//     // mapping(address => uint256 claimedEvolveNum) public s_nation_supporters; // all people inside one country

//     mapping(address => LotteryQualification) s_community_lottery_3_Participants;

//     mapping(address => uint256 claimedEvolveNum) s_unstoppable_4_duki_influencers;

//     mapping(address => uint256 claimedEvolveNum) s_wind_3_contributors;

//     // s_baguaDaoUnitCountArr records fair drop count, community are participants including subscribers,investors,maintainers except duki participants without other interactions
//     uint256 public s_unstoppableInvestorsCount; // < MaxLifetimeSupportersTotal limited lifetime uns user subscription

//     uint256 public s_unstoppableSubscriberCount; // normal uns user subscription, without limit

//     mapping(address => uint256 claimedEvolveNum) s_earth_0_founders;

//     mapping(address => uint256 claimedEvolveNum) s_mountain_1_maintainers;

//     mapping(uint256 => uint256 claimedEvolveNum) s_water_2_investors;

//     //unstoppable domain subscription
//     mapping(uint256 => uint256) s_unstoppableSubscriptions; // normal uns tokenId, uint64.max means investment ,which is lifetime

//     // Reserved storage slots for future upgrades
//     // This ensures we can add new storage variables without corrupting existing storage layout
//     uint256[49] private __gap;

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() {
//         _disableInitializers();
//     }

//     function initialize(UnstoppableConfig memory config) public initializer {
//         __UUPSUpgradeable_init();
//         __Ownable_init(msg.sender);

//         s_subscription_yearly_fee = Initial_Subscription_Yearly_Fee;
//         s_investment_3_fee = DukiDaoConstants.BASIC_INVEST_AMOUNT;
//         s_daoEvolveNum = 0; // initial 0,  monotonic increasing
//         s_daoEvolveBlockNum = 0; // 0 means not evolve yet, when evolved, it becomes block.number;
//         s_bornSeconds = block.timestamp;

//         //        s_unsRegistry = IMinUNSRegistry(config.unsRegistry);
//         s_unsRegistry = config.unsRegistry;
//         s_stableCoin = config.stableCoin;

//         s_baguaDaoBpsArr = [
//             DukiDaoConstants.Initial_0_Founders_Bps,
//             DukiDaoConstants.Initial_1_Maintainers_Bps,
//             DukiDaoConstants.Initial_2_Investors_Bps,
//             DukiDaoConstants.Initial_3_Contributors_Bps,
//             DukiDaoConstants.Initial_4_Builders_Bps,
//             DukiDaoConstants.Initial_5_Community_Bps,
//             DukiDaoConstants.Initial_6_ALM_Nation_DukiInAction_Bps, // DUKI for all - empower all to reject evil, do good and be love
//             DukiDaoConstants.Initial_7_ALM_World_DukiInAction_Bps // DUKI for all - empower all to reject evil, do good and be love
//         ];

//         // 1. Validate and set shares
//         for (uint256 i = 0; i < config.creators.length; i++) {
//             if (config.creators[i] == address(0)) revert DukiDaoTypes.ZeroAddressError();
//             s_earth_0_founders[config.creators[i]] = DukiDaoConstants.Initial_Evolve_Round;
//         }

//         s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_0_Earth_Founders] = config.creators.length;

//         uint256[8] memory emptyArr;

//         for (uint256 i = 0; i < config.maintainers.length; i++) {
//             if (config.maintainers[i] == address(0)) revert DukiDaoTypes.ZeroAddressError();
//             s_mountain_1_maintainers[config.maintainers[i]] = DukiDaoConstants.Initial_Evolve_Round;
//         }

//         s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_1_Mountain_Maintainers] = config.maintainers.length;

//         emit DukiDaoTypes.BaguaDukiDaoBpsChanged(emptyArr, s_baguaDaoBpsArr);
//     }

//     // Authorization function for contract upgrades
//     function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
//         require(newImplementation != address(0), "New implementation cannot be zero address");
//     }

//     function updateBaguaDaoBps(uint256[8] calldata newDaoBpsArr) public {
//         uint256 total = 0;
//         for (uint256 i = 0; i < 8; i++) {
//             total += newDaoBpsArr[i];
//         }
//         if (total != DukiDaoConstants.BPS_PRECISION) {
//             revert DukiDaoTypes.BpsSumError();
//         }

//         uint256[8] memory oldBaguaBpsShares = s_baguaDaoBpsArr;
//         s_baguaDaoBpsArr = newDaoBpsArr;
//         // Emit events
//         emit DukiDaoTypes.BaguaDukiDaoBpsChanged(oldBaguaBpsShares, s_baguaDaoBpsArr);
//     }

//     modifier mustBeUnstoppableDomain(string memory label) {
//         if (LibString.startsWith(label, UNS_TEST_DOMAIN)) {
//             revert UnsTestDomainError();
//         }
//         if (LibString.contains(label, ".")) {
//             revert UnsSubDomainForbidden();
//         }
//         _;
//     }

//     function lotteryQualification(address user) external view override returns (LotteryQualification memory) {
//         return s_community_lottery_3_Participants[user];
//     }

//     function baguaDaoUnitCountArr() external view override returns (uint256[8] memory) {
//         return s_baguaDaoUnitCountArr;
//     }

//     function baguaDaoFairDropArr() external view override returns (DukiDaoTypes.DaoFairDrop[8] memory) {
//         return s_baguaDaoFairDropArr;
//     }

//     function baguaDaoBpsArr() external view override returns (uint256[8] memory) {
//         return s_baguaDaoBpsArr;
//     }

//     function expireSecondsOfSubscription(string calldata uns_domain) external view returns (uint256) {
//         uint256 uns_domain_token = uns_domain_to_token(uns_domain);
//         return s_unstoppableSubscriptions[uns_domain_token];
//     }

//     function baguaDaoAgg4Me(address user, string calldata uns_domain)
//         external
//         view
//         override
//         returns (BaguaDaoAgg memory)
//     {
//         uint256 curEvolveBlockNum = s_daoEvolveBlockNum;

//         // if uns_domain 's length = 0, it means the caller is not an unstoppable domain owner
//         bool almQualified = true;
//         bool unsDomainIsEmpty = bytes(uns_domain).length == 0;
//         bool investorClaimedQualified = false;
//         uint256 subscriptionExpireSeconds = 0;

//         uint256[8] memory claimedRoundArr;
//         claimedRoundArr[0] = s_daoEvolveBlockNum;

//         if (!unsDomainIsEmpty) {
//             uint256 uns_domain_token = uns_domain_to_token(uns_domain);
//             subscriptionExpireSeconds = s_unstoppableSubscriptions[uns_domain_token];
//             claimedRoundArr[7] = s_alm_7_dukiClaimerDomains[uns_domain_token];
//             claimedRoundArr[2] = s_water_2_investors[uns_domain_token];
//         }

//         LotteryQualification memory qualification = s_community_lottery_3_Participants[user];
//         claimedRoundArr[5] = qualification.claimedRound;

//         uint256 lotteryWinnerNumber = s_baguaDaoFairDropArr[0].unitNumber;

//         if (user != address(0)) {
//             claimedRoundArr[4] = s_unstoppable_4_duki_influencers[user];
//             claimedRoundArr[3] = s_wind_3_contributors[user];
//             claimedRoundArr[1] = s_mountain_1_maintainers[user];
//             claimedRoundArr[0] = s_earth_0_founders[user];
//         }

//         return BaguaDaoAgg(
//             s_bornSeconds,
//             subscriptionExpireSeconds,
//             s_lotteryWinnerNumber,
//             qualification.participantNum,
//             s_claimed_amount,
//             claimedRoundArr,
//             s_baguaDaoBpsArr,
//             s_baguaDaoUnitCountArr,
//             s_baguaDaoFairDropArr
//         );
//     }

//     /**
//      * daoDistribution
//      */
//     function evolveDaoThenDistribute(uint32 lotteryWinnerNumber) external returns (bool, uint256) {
//         // CHECKS
//         IERC20 stableCoin = IERC20(s_stableCoin);
//         uint256 balance = stableCoin.balanceOf(address(this));

//         if (balance < DukiDaoConstants.DAO_START_EVOLVE_AMOUNT) {
//             console2.log(
//                 "balance < DAO_START_EVOLVE_AMOUNT, skip evolveDaoThenDistribute",
//                 balance,
//                 DukiDaoConstants.DAO_START_EVOLVE_AMOUNT
//             );
//             return (false, s_daoEvolveNum);
//         }

//         uint256 distributionAmount = balance - DukiDaoConstants.DAO_EVOLVE_LEFT_AMOUNT;

//         // EFFECTS
//         uint256 currentEvolveNum = s_daoEvolveNum + 1;
//         uint256 currentEvolveBlockNum = block.number;
//         s_daoEvolveNum = currentEvolveNum;
//         s_daoEvolveBlockNum = currentEvolveBlockNum;
//         s_lotteryWinnerNumber = lotteryWinnerNumber;

//         DukiDaoTypes.DaoFairDrop[8] memory daoFairDrops;

//         //  dukiInAction
//         uint256[8] memory bpsUnitNumArr = s_baguaDaoUnitCountArr;

//         // iterate over baguaDaoUnitTotals
//         for (uint256 i = 0; i < 8; i++) {
//             uint256 bpsAmount = (s_baguaDaoBpsArr[i] * distributionAmount) / DukiDaoConstants.BPS_PRECISION;

//             uint256 bpsUnitNum = bpsUnitNumArr[i];

//             if (bpsAmount == 0) {
//                 continue;
//             }

//             if (DukiDaoConstants.SEQ_7_Heaven_ALM_DukiInAction == i) {
//                 bpsUnitNum = bpsAmount / DukiDaoConstants.DukiInAction_StableCoin_Claim_Amount;

//                 daoFairDrops[i] = DukiDaoTypes.DaoFairDrop(DukiDaoConstants.DukiInAction_StableCoin_Claim_Amount, bpsUnitNum, bpsUnitNum);
//             } else if (DukiDaoConstants.SEQ_5_Fire_Community_Participants == i) {
//                 if (bpsUnitNum == 0) {
//                     continue;
//                 }

//                 // lottery for community
//                 // uint256 lotteryUsersNum = s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_5_Fire_Community_Participants];
//                 // fixme
//                 uint256 unitTotalNum = 1;
//                 uint256 unitAmount = bpsAmount / unitTotalNum;
//                 daoFairDrops[i] = DukiDaoTypes.DaoFairDrop(unitAmount, unitTotalNum, unitTotalNum);
//             } else {
//                 if (bpsUnitNum == 0) {
//                     continue;
//                 }
//                 uint256 unitAmount = bpsAmount / bpsUnitNum;
//                 daoFairDrops[i] = DukiDaoTypes.DaoFairDrop(unitAmount, bpsUnitNum, bpsUnitNum);
//             }
//         }

//         // Set the values in batch
//         for (uint256 i = 0; i < daoFairDrops.length; i++) {
//             s_baguaDaoFairDropArr[i] = daoFairDrops[i];
//         }

//         emit DukiDaoEvolution(s_daoEvolveBlockNum, lotteryWinnerNumber, daoFairDrops, block.timestamp);
//         return (true, s_daoEvolveNum);
//     }

//     function uns_domain_to_token(string calldata uns_domain) internal view returns (uint256) {
//         string[] memory uns_domain_labels = new string[](2);
//         uns_domain_labels[0] = uns_domain;
//         uns_domain_labels[1] = UNS_TLD;
//         IMinUNSRegistry unsRegistry = IMinUNSRegistry(s_unsRegistry);
//         return unsRegistry.namehash(uns_domain_labels);
//     }

//     function validateAndConvertUnsDomain(string calldata uns_domain, address uns_domain_owner)
//         internal
//         view
//         mustBeUnstoppableDomain(uns_domain)
//         returns (uint256)
//     {
//         uint256 uns_domain_token = uns_domain_to_token(uns_domain);
//         IMinUNSRegistry unsRegistry = IMinUNSRegistry(s_unsRegistry);
//         address token_owner = unsRegistry.ownerOf(uns_domain_token);
//         if (token_owner != uns_domain_owner) {
//             console2.log("msgSender,token_owner is ", uns_domain_owner, token_owner);
//             revert NotUnsDomainOwnerError();
//         }

//         return uns_domain_token;
//     }

//     /**
//      *
//      * @param uns_domain unstoppable domain name, e.g. "kindkang.unstoppable", use kindkang only
//      * @param _subYears  the number of years to subscribe ; when value = 0, it means invest lifetime subscription
//      */
//     function payToSubscribe(string calldata uns_domain, uint32 _subYears) external {
//         // Interactions
//         // coin transfer
//         // function allowance(address owner, address spender) external view returns (uint256);
//         // CHECKS
//         if (msg.sender == address(0)) {
//             revert DukiDaoTypes.ZeroAddressError();
//         }
//         if (_subYears < 1) {
//             revert SubscriptionYearsInvalid();
//         }

//         uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);
//         // check if the subscription already exists
//         if (s_unstoppableSubscriptions[uns_domain_token] != 0) {
//             console2.log("uns_domain_token exists -> SubscriptionExistsError");
//             revert SubscriptionExistsError();
//         }

//         // uint256 subscription_required_coin = Lifetime_Subscription_Represent_Value;
//         // uint256 expireTimeSeconds = LIFE_TIME_EXPIRE_SECONDS;
//         uint256 subscription_required_coin = _subYears * s_subscription_yearly_fee;
//         console2.log("sub fees=yearly_fee*years = ", s_subscription_yearly_fee, _subYears, subscription_required_coin);
//         uint256 expireTimeSeconds = block.timestamp + (_subYears * 365 days);

//         // if (isLifetimeSubscription) {
//         //   expireTime = LIFE_TIME_EXPIRE_SECONDS;
//         //   // EFFECTS
//         //   s_unstoppableSubscriptions[uns_domain_token] = expireTimeSeconds;
//         //   s_unstoppableInvestorsCount += 1;
//         // } else {
//         //   s_unstoppableSubscriberCount += 1;
//         // }

//         // EFFECTS
//         s_unstoppableSubscriberCount += 1;
//         s_unstoppableSubscriptions[uns_domain_token] = expireTimeSeconds;

//         addToCommunityForLottery();

//         commonDeductFee(DukiDaoTypes.InteractType.In_To_Service, subscription_required_coin, _subYears, uns_domain);
//     }

//     function isStructExist(LotteryQualification memory qualification) internal pure returns (bool) {
//         return qualification.participantNum > 0;
//     }

//     function payToExtend(string calldata uns_domain, uint32 _extendYears)
//         external
//         mustBeUnstoppableDomain(uns_domain)
//     {
//         if (_extendYears < 1) {
//             revert SubscriptionYearsInvalid();
//         }

//         uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

//         uint256 expireSeconds = s_unstoppableSubscriptions[uns_domain_token];

//         if (expireSeconds == 0) {
//             revert SubscriptionNotExist();
//         }

//         if (expireSeconds == DukiDaoConstants.LIFE_TIME_EXPIRE_SECONDS) {
//             revert NoNeedExtendLifetimeSubscription();
//         }

//         if (expireSeconds < block.timestamp) {
//             expireSeconds = block.timestamp;
//         }

//         // Add subscription time
//         uint256 newExpireSeconds = expireSeconds + (_extendYears * 365 days);

//         // Store the new expiration
//         s_unstoppableSubscriptions[uns_domain_token] = newExpireSeconds;

//         uint256 subscription_required_coin = _extendYears * s_subscription_yearly_fee;

//         // uint256 allowanceMoney = stableCoin.allowance(msg.sender, address(this));
//         // if (allowanceMoney < subscription_required_coin) {
//         //   revert InsufficientAllowance(
//         //     CoinReceiveType.Extend_Subscription,
//         //     msg.sender,
//         //     subscription_required_coin
//         //   );
//         // }

//         s_unstoppableSubscriptions[uns_domain_token] = newExpireSeconds;

//         commonDeductFee(DukiDaoTypes.InteractType.In_To_Extend_Service, subscription_required_coin, _extendYears, uns_domain);
//     }

//     function addToCommunityForLottery() internal returns (bool) {
//         if (s_community_lottery_3_Participants[msg.sender].participantNum > 0) {
//             return false;
//         }

//         s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_5_Fire_Community_Participants] += 1;
//         s_community_lottery_3_Participants[msg.sender] = LotteryQualification(
//             block.number, s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_5_Fire_Community_Participants]
//         );
//         // emit CommunityLotteryEntry(
//         //   msg.sender, bonusEntry, s_baguaDaoUnitCountArr[SEQ_5_Fire_Community_Participants]
//         // );
//         return true;
//     }

//     /**
//      * a way to support, at least 10% of the total project revenue will be shared with the investors
//      */
//     function payToInvestUnsInLimo(string calldata uns_domain) external override mustBeUnstoppableDomain(uns_domain) {
//         uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

//         // CHECKS
//         if (s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_2_Water_Investors] > DukiDaoConstants.MaxInvestorsTotal) {
//             revert DukiDaoTypes.BaguaRoleFull(DukiDaoConstants.SEQ_2_Water_Investors);
//         }

//         if (s_water_2_investors[uns_domain_token] >= DukiDaoConstants.Initial_Evolve_Round) {
//             revert DukiDaoTypes.AlreadyInvested();
//         }

//         // EFFECTS
//         s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_2_Water_Investors] += 1;
//         s_water_2_investors[uns_domain_token] = block.number;

//         // @dev use could be an subscriber before, now upgrade becomes an investor,
//         // . but no money back for previous subscription , lottery qualification still keeps
//         s_unstoppableSubscriptions[uns_domain_token] = DukiDaoConstants.LIFE_TIME_EXPIRE_SECONDS;

//         // INTERACTIONS
//         commonDeductFee(DukiDaoTypes.InteractType.In_To_Invest, s_investment_3_fee, 1, uns_domain);

//         // emit InvestorAdded(
//         //   msg.sender, s_baguaDaoUnitCountArr[SEQ_2_Water_Investors]
//         // );
//     }

//     /**
//      *
//      * @param uns_domain the unstoppable domain name, e.g. "kindkang.unstoppable", use kindkang only
//      */
//     function claim7_AlmDukiInActionFairDrop(string calldata uns_domain) external mustBeUnstoppableDomain(uns_domain) {
//         // CHECKS

//         uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

//         uint256 domainClaimedEvolveNum = s_alm_7_dukiClaimerDomains[uns_domain_token];
//         if (domainClaimedEvolveNum >= s_daoEvolveBlockNum) {
//             console2.log(
//                 "claim1_AlmDukiInActionFairDrop already claimed",
//                 msg.sender,
//                 domainClaimedEvolveNum,
//                 s_daoEvolveBlockNum
//             );
//             revert DukiDaoTypes.ClaimedCurrentRoundAlreadyError();
//         }

//         DukiDaoTypes.DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[DukiDaoConstants.SEQ_7_Heaven_ALM_DukiInAction];

//         if (fairDrop.unitNumber <= 0) {
//             console2.log("claim1_AlmDukiInActionFairDrop no distribution unit left", msg.sender);
//             revert DukiDaoTypes.NoDistributionUnitLeft();
//         }

//         // EFFECTS
//         s_alm_7_dukiClaimerDomains[uns_domain_token] = s_daoEvolveBlockNum;
//         fairDrop.unitNumber -= 1;
//         s_baguaDaoUnitCountArr[DukiDaoConstants.SEQ_7_Heaven_ALM_DukiInAction] += 1; // no use ,just for stats

//         s_claimed_amount += fairDrop.unitAmount;
//         // INTERACTIONS
//         IERC20 stableCoin = IERC20(s_stableCoin);
//         bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
//         if (!success) {
//             revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
//         }

//         emit UnstoppableEvent(
//             msg.sender,
//             s_daoEvolveNum,
//             DukiDaoTypes.InteractType.Out_Claim1_As_Duki4World,
//             fairDrop.unitAmount,
//             fairDrop.unitNumber,
//             uns_domain,
//             block.timestamp
//         );
//     }

//     /**
//      */
//     function claim5_CommunityLotteryDrop() external {
//         // CHECKS
//         LotteryQualification storage qualification = s_community_lottery_3_Participants[msg.sender];

//         if (qualification.participantNum == 0) {
//             console2.log("claim3_CommunityLotteryDrop not in lottery community", msg.sender);
//             revert NotInLottery();
//         }
//         uint256 participantWinNumber = qualification.participantNum % DukiDaoConstants.MaxLotteryParticipantNumber;

//         if (winnerNumber != participantWinNumber) {
//             console2.log("claim3_CommunityLotteryDrop not winner", msg.sender, winnerNumber, participantWinNumber);
//             revert NotLotteryWinner();
//         }

//         if (qualification.claimedRound == s_daoEvolveBlockNum) {
//             console2.log(
//                 "claim3_CommunityLotteryDrop already claimed",
//                 msg.sender,
//                 qualification.claimedRound,
//                 s_daoEvolveBlockNum
//             );
//             revert DukiDaoTypes.ClaimedCurrentRoundAlreadyError();
//         }

//         DukiDaoTypes.DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[DukiDaoConstants.SEQ_5_Fire_Community_Participants];
//         if (fairDrop.unitNumber == 0) {
//             revert DukiDaoTypes.NoDistributionUnitLeft();
//         }

//         // EFFECTS
//         fairDrop.unitNumber -= 1;
//         qualification.claimedRound = s_daoEvolveBlockNum;
//         s_claimed_amount += fairDrop.unitAmount;

//         // INTERACTIONS
//         IERC20 stableCoin = IERC20(s_stableCoin);
//         bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
//         if (!success) {
//             revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
//         }
//         console2.log("claim3_CommunityLotteryDrop", msg.sender, fairDrop.unitAmount);

//         emit UnstoppableEvent(
//             msg.sender,
//             s_daoEvolveBlockNum,
//             DukiDaoTypes.InteractType.Out_Claim3_As_CommunityStar,
//             fairDrop.unitAmount,
//             1,
//             "",
//             block.timestamp
//         );
//     }

//     function claim4_InfluencerFairDrop() external {
//         common_claim(
//             DukiDaoTypes.InteractType.Out_Claim4_As_Influencer,
//             DukiDaoConstants.SEQ_4_Thunder_DukiInfluencers,
//             s_unstoppable_4_duki_influencers
//         );
//     }

//     function claim3_ContributorFairDrop() external {
//         common_claim(
//             DukiDaoTypes.InteractType.Out_Claim3_As_Contributor,
//             DukiDaoConstants.SEQ_3_Wind_Contributors,
//             s_wind_3_contributors
//         );
//     }

//     function claim2_UnsInvestorFairDrop(string calldata uns_domain) external mustBeUnstoppableDomain(uns_domain) {
//         uint256 uns_domain_token = validateAndConvertUnsDomain(uns_domain, msg.sender);

//         uint256 claimedRound = s_water_2_investors[uns_domain_token];

//         if (claimedRound < DukiDaoConstants.Initial_Evolve_Round) {
//             console2.log("claim6_UnsInvestorFairDrop is not investor", msg.sender);
//             revert DukiDaoTypes.NotHasRole(DukiDaoConstants.SEQ_2_Water_Investors);
//         }

//         if (claimedRound >= s_daoEvolveBlockNum) {
//             console2.log("claim6_UnsInvestorFairDrop already claimed", msg.sender, claimedRound, s_daoEvolveBlockNum);
//             revert DukiDaoTypes.ClaimedCurrentRoundAlreadyError();
//         }

//         // EFFECTS
//         DukiDaoTypes.DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[DukiDaoConstants.SEQ_2_Water_Investors];
//         fairDrop.unitNumber -= 1;
//         s_water_2_investors[uns_domain_token] = s_daoEvolveBlockNum;
//         s_claimed_amount += fairDrop.unitAmount;

//         // INTERACTIONS
//         IERC20 stableCoin = IERC20(s_stableCoin);
//         bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
//         if (!success) {
//             revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
//         }

//         console2.log("claim6_UnsInvestorFairDrop", msg.sender, fairDrop.unitAmount, fairDrop.unitNumber);

//         emit UnstoppableEvent(
//             msg.sender,
//             s_daoEvolveBlockNum,
//             DukiDaoTypes.InteractType.Out_Claim2_As_Investor,
//             fairDrop.unitAmount,
//             1,
//             "",
//             block.timestamp
//         );
//     }

//     function claim1_MaintainerFairDrop() external {
//         common_claim(
//             DukiDaoTypes.InteractType.Out_Claim1_As_Maintainer,
//             DukiDaoConstants.SEQ_1_Mountain_Maintainers,
//             s_mountain_1_maintainers
//         );
//     }

//     function claim0_FounderFairDrop() external {
//         common_claim(
//             DukiDaoTypes.InteractType.Out_Claim0_As_Founder, DukiDaoConstants.SEQ_0_Earth_Founders, s_earth_0_founders
//         );
//     }

//     function common_claim(
//         DukiDaoTypes.InteractType interactType,
//         uint256 seq,
//         mapping(address => uint256 claimedEvolveNum) storage claimMap
//     ) internal {
//         if (msg.sender == address(0)) {
//             revert DukiDaoTypes.ZeroAddressError();
//         }

//         uint256 claimedRound = claimMap[msg.sender];

//         if (claimedRound < DukiDaoConstants.Initial_Evolve_Round) {
//             console2.log("common_claim is not qualified", msg.sender, claimedRound);
//             revert DukiDaoTypes.NotQualifiedForClaim(interactType);
//         }

//         if (claimedRound == s_daoEvolveBlockNum) {
//             console2.log("common_claim already claimed", msg.sender, claimedRound, s_daoEvolveBlockNum);
//             revert DukiDaoTypes.ClaimedCurrentRoundAlreadyError();
//         }

//         if (claimedRound > s_daoEvolveBlockNum) {
//             console2.log(
//                 "common_claim joined after current dao distribution, not qualified",
//                 msg.sender,
//                 claimedRound,
//                 s_daoEvolveBlockNum
//             );
//             revert DukiDaoTypes.LateForCurrentClaim();
//         }

//         DukiDaoTypes.DaoFairDrop storage fairDrop = s_baguaDaoFairDropArr[seq];

//         // EFFECTS
//         fairDrop.unitNumber -= 1;
//         claimMap[msg.sender] = s_daoEvolveBlockNum;
//         s_claimed_amount += fairDrop.unitAmount;

//         // INTERACTIONS
//         IERC20 stableCoin = IERC20(s_stableCoin);
//         bool success = stableCoin.transfer(msg.sender, fairDrop.unitAmount);
//         if (!success) {
//             revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
//         }

//         emit UnstoppableEvent(
//             msg.sender, s_daoEvolveBlockNum, interactType, fairDrop.unitAmount, 1, "", block.timestamp
//         );
//     }

//     function commonDeductFee(
//         DukiDaoTypes.InteractType interactType,
//         uint256 requiredMoney,
//         uint256 units,
//         string memory uns_domain
//     ) internal {
//         IERC20 stableCoin = IERC20(s_stableCoin);
//         uint256 allowanceMoney = stableCoin.allowance(msg.sender, address(this));
//         if (allowanceMoney < requiredMoney) {
//             console2.log("InsufficientAllowance:allowanceMoney < requiredMoney", allowanceMoney, requiredMoney);
//             revert DukiDaoTypes.InsufficientAllowance(interactType, msg.sender, requiredMoney);
//         }

//         bool success = stableCoin.transferFrom(msg.sender, address(this), requiredMoney);

//         console2.log("CoinReceived, requiredMoney from", success, requiredMoney, units);

//         if (success) {
//             emit UnstoppableEvent(
//                 msg.sender, s_daoEvolveBlockNum, interactType, requiredMoney, units, uns_domain, block.timestamp
//             );
//         } else {
//             console2.log("TransferFailed:TransferFailed");
//             revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.In, msg.sender, requiredMoney);
//         }
//     }

//     /**
//      * Function that allows the contract to receive ETH
//      */
//     receive() external payable { }

//     // function claim5_ContributorFairDrop() external override {}
// }
