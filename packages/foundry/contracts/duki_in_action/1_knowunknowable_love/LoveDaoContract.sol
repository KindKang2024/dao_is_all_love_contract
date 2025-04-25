//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@/dependencies/IAnyrand.sol";
import "@/dependencies/IRandomiserCallbackV3.sol";
import "@/dependencies/IZkHumanRegistry.sol";

// Useful for debugging. Remove when deploying to a live network.
import "@/libraries/DukiDaoConstants.sol";
import "@/libraries/DukiDaoTypes.sol";
import "@/duki_in_action/1_knowunknowable_love/ILoveBaguaDao.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@solady/utils/LibString.sol";

/**
 * A DAO contract works as an naiive proof of concept to demonstrate how DUKI in Action works in the real world.
 *
 * Duki In Action could be the global marketing strategy for any serious business entity that has a global vision.
 * ~ All Attention is All You Need To Make All Great Again. ~
 *
 * @author KindKang2024
 */
contract LoveDaoContract is Initializable, UUPSUpgradeable, OwnableUpgradeable, ILoveBaguaDao, IRandomiserCallbackV3 {
    address public s_stableCoin;
    // Anyrand related variables
    address public s_anyrand;

    uint256 public s_lastRandomnessWillId;
    uint256 public s_lastRandomnessWillTimestamp;
    uint256 public s_lastRandomnessWillCallbackTimestamp;

    // Configurable time parameters
    uint256 public s_minWaitBetweenEvolutions; // Minimum time between evolution attempts (default 7 days)
    uint256 public s_randomnessRequestDeadline; // Seconds into the future for randomness request deadline (default 300s)

    uint256[8] s_dao_bps_arr;
    // calculate total unit for each trigram dynamically
    uint256[8] s_dao_bps_count_arr;

    // each
    uint256 public s_dao_born_seconds; // the timestamp when the dao was created
    uint256 public s_dao_evolve_round; // start from 1,  monotonic increasing step=1
    DukiDaoTypes.DaoFairDrop[8] s_dao_fair_drop_arr;

    uint256 private s_dao_claimed_amount;

    uint256 s_investment_3_fee;

    uint256 public s_community_lucky_participant_no;
    uint256 public s_event_id;

    mapping(address => uint256 claimedEvolveNum) s_earth_0_founders;

    mapping(address => uint256 claimedEvolveNum) s_mountain_1_maintainers;

    mapping(address => uint256 claimedEvolveNum) s_water_2_investors;

    mapping(address => uint256 claimedEvolveNum) s_wind_3_contributors;
    mapping(address => uint256 claimedEvolveNum) s_thunder_4_duki_influencers;

    mapping(address => DukiDaoTypes.CommunityParticipation) s_community_5_Participants;

    mapping(address => mapping(bytes16 => Divination)) s_dao_love_connections;

    mapping(address => uint256 claimedEvolveNum) s_alm_nation_6_supporters; // all people inside one country

    mapping(address => uint256 claimedEvolveNum) s_alm_world_7_dukiClaimers; // requires to be a unique human being, concept now;

    // Keep track of authorized Automation addresses
    address public automationRegistry;

    // just a slot for IZkHumanRegistry, currently not in use
    // address public humanZkpRegistry;

    // Reserved storage slots for future upgrades
    // This ensures we can add new storage variables without corrupting existing storage layout
    uint256[49] private __gap;

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // constructor(NetworkConfig memory config) {
    //     initialize(config);
    // }

    function isZkProvedHuman(address user) private view returns (bool) {
        // currently do not have such service backedup by true authority todo : DUKI in Action need this
        // here we just check the balance of the user is greater than 1 dollar. Useless but just for the concept
        return IERC20(s_stableCoin).balanceOf(user) > DukiDaoConstants.ONE_DOLLAR_BASE;
    }

    // Authorization function for contract upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        if (newImplementation == address(0)) revert DukiDaoTypes.ZeroAddressError();
    }

    function initialize(DukiDaoTypes.NetworkConfig memory config) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);

        if (config.stableCoin == address(0)) revert DukiDaoTypes.ZeroAddressError(); // Add this check
        if (config.anyrand == address(0)) revert DukiDaoTypes.ZeroAddressError(); // Check anyrand address

        s_investment_3_fee = DukiDaoConstants.BASIC_INVEST_AMOUNT;
        s_dao_evolve_round = DukiDaoConstants.Initial_Evolve_Round; //  monotonic increasing. when it evolves, it will be 2, so could be different from others intial claim round = 1
        s_dao_born_seconds = block.timestamp;

        s_stableCoin = config.stableCoin;
        s_anyrand = config.anyrand;

        // Initialize time parameters with defaults
        s_minWaitBetweenEvolutions = 7 days;
        s_randomnessRequestDeadline = 300; // 5 minutes

        s_dao_bps_arr = [
            DukiDaoConstants.Initial_0_Founders_Bps,
            DukiDaoConstants.Initial_1_Maintainers_Bps,
            DukiDaoConstants.Initial_2_Investors_Bps,
            DukiDaoConstants.Initial_3_Contributors_Bps,
            DukiDaoConstants.Initial_4_Builders_Bps,
            DukiDaoConstants.Initial_5_Community_Bps,
            DukiDaoConstants.Initial_6_ALM_Nation_DukiInAction_Bps, // DUKI for all - empower all to reject evil, do good and be love
            DukiDaoConstants.Initial_7_ALM_World_DukiInAction_Bps // DUKI for all - empower all to reject evil, do good and be love
        ];

        // 1. Validate and set shares
        for (uint256 i = 0; i < config.creators.length; i++) {
            if (config.creators[i] == address(0)) revert DukiDaoTypes.ZeroAddressError();
            s_earth_0_founders[config.creators[i]] = DukiDaoConstants.Initial_Evolve_Round;
        }

        s_dao_bps_count_arr[DukiDaoConstants.SEQ_0_Earth_Founders] = config.creators.length;

        uint256[8] memory emptyArr;
        for (uint256 i = 0; i < config.maintainers.length; i++) {
            if (config.maintainers[i] == address(0)) revert DukiDaoTypes.ZeroAddressError();
            s_mountain_1_maintainers[config.maintainers[i]] = DukiDaoConstants.Initial_Evolve_Round;
        }
        s_dao_bps_count_arr[DukiDaoConstants.SEQ_1_Mountain_Maintainers] = config.maintainers.length;

        emit DukiDaoTypes.BaguaDukiDaoBpsChanged(emptyArr, s_dao_bps_arr);
    }

    function baguaDaoUnitCountArr() external view returns (uint256[8] memory) {
        return s_dao_bps_count_arr;
    }

    function baguaDaoFairDropArr() external view returns (DukiDaoTypes.DaoFairDrop[8] memory) {
        return s_dao_fair_drop_arr;
    }

    function baguaDaoBpsArr() external view override returns (uint256[8] memory) {
        return s_dao_bps_arr;
    }

    function baguaDaoAgg4Me(address user) external view override returns (BaguaDaoAgg memory) {
        DukiDaoTypes.CommunityParticipation memory participation = s_community_5_Participants[user];

        uint256[8] memory userClaimedRoundArr = [
            s_earth_0_founders[user],
            s_mountain_1_maintainers[user],
            s_water_2_investors[user],
            s_wind_3_contributors[user],
            s_thunder_4_duki_influencers[user],
            participation.luckyClaimedRound,
            s_alm_nation_6_supporters[user],
            s_alm_world_7_dukiClaimers[user]
        ];

        uint256 currentEvolveRound = s_dao_evolve_round;

        uint256 stableCoinBalance = IERC20(s_stableCoin).balanceOf(user);

        return BaguaDaoAgg(
            currentEvolveRound,
            s_dao_born_seconds,
            s_dao_claimed_amount,
            stableCoinBalance,
            s_dao_bps_arr,
            s_dao_bps_count_arr,
            s_dao_fair_drop_arr,
            s_community_lucky_participant_no,
            userClaimedRoundArr,
            participation
        );
    }

    function connectDaoToKnow(
        bytes16 diviUuid,
        bytes32 diviWillHash,
        bytes16 diviWillAnswer,
        uint256 willPowerAmount, // money amount
        // Permit parameters
        uint256 permitDeadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external {
        // CHECKS
        if (msg.sender == address(0)) {
            revert DukiDaoTypes.ZeroAddressError();
        }

        if (willPowerAmount > DukiDaoConstants.MAX_POWER_AMOUNT) {
            revert DukiDaoTypes.ExcessiveAmount();
        }

        // money as power must > 0
        if (willPowerAmount <= 0) {
            revert LoveAsMoneyIntoDaoRequired();
        }

        // Check if this divination UUID has already been used by this user to avoid double payment
        if (s_dao_love_connections[msg.sender][diviUuid].diviWillHash != bytes32(0)) {
            revert DaoConnectedAlready();
        }

        // Call permit on the token before transferring
        IERC20Permit(s_stableCoin).permit(
            msg.sender,
            address(this),
            willPowerAmount,
            permitDeadline,
            permitV,
            permitR,
            permitS
        );

        // EFFECTS
        // user first join the community
        if (s_community_5_Participants[msg.sender].participantNo <= 0) {
            s_dao_bps_count_arr[DukiDaoConstants.SEQ_5_Fire_Community_Participants] += 1;
            s_community_5_Participants[msg.sender] = DukiDaoTypes.CommunityParticipation(
                s_dao_bps_count_arr[DukiDaoConstants.SEQ_5_Fire_Community_Participants],
                willPowerAmount,
                DukiDaoConstants.Initial_Evolve_Round
            );
        } else {
            s_community_5_Participants[msg.sender].participantAmount += willPowerAmount;
        }
        commonDeductFee(DukiDaoTypes.InteractType.In_To_Service, willPowerAmount);

        // save the divination info
        s_dao_love_connections[msg.sender][diviUuid] =
            Divination(KnownStatus.Unknown, diviWillHash, diviWillAnswer, willPowerAmount);
        emit ConnectDaoEvent(diviUuid, msg.sender, diviWillHash, willPowerAmount, block.timestamp);
    }

    // after verified the divination, the user can vow to the dao
    function vowDaoManifestation(
        bytes16 diviUuid,
        KnownStatus knownStatus,
        uint256 vowPowerAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (knownStatus == KnownStatus.Unknown) {
            revert InvalidKnownStatus();
        }
        if (vowPowerAmount > 0 || deadline > 0 || v > 0) {
            // currently do not support
            revert DukiDaoTypes.NotSupported("vowDaoManifestation with vowPowerAmount");
        }

        //   add dao power  maybe or never
        // save the vow info
        s_dao_love_connections[msg.sender][diviUuid].knownStatus = knownStatus;
        emit VowDaoEvent(diviUuid, msg.sender, knownStatus, 0, block.timestamp);
    }

    function isStructExist(DukiDaoTypes.CommunityParticipation memory qualification) internal pure returns (bool) {
        return qualification.participantNo > 0;
    }

    function approveAsContributor(address requestor) external maintainerOnly {
        addAsDaoObserver(requestor, DukiDaoConstants.SEQ_3_Wind_Contributors, s_wind_3_contributors, 0);
    }

    function approveAsDukiInfluencer(address requestor) external maintainerOnly {
        addAsDaoObserver(
            requestor,
            DukiDaoConstants.SEQ_4_Thunder_DukiInfluencers,
            s_thunder_4_duki_influencers,
            DukiDaoConstants.MaxInfluencerTotal
        );
    }

    // add as observer for the dao
    function addAsDaoObserver(
        address observer,
        uint256 observerRoleSeq,
        mapping(address => uint256) storage observerMap,
        uint256 observerRoleMaxCount
    ) private {
        if (observerRoleMaxCount > 0 && s_dao_bps_count_arr[observerRoleSeq] >= observerRoleMaxCount) {
            revert DukiDaoTypes.BaguaRoleFull(observerRoleSeq);
        }
        s_dao_bps_count_arr[observerRoleSeq] += 1;
        observerMap[observer] = DukiDaoConstants.Initial_Evolve_Round;
    }

    /**
     * a way to support
     */
    function connectDaoToInvest() external {
        // Check if user has already invested - return silently if true
        if (s_water_2_investors[msg.sender] >= DukiDaoConstants.Initial_Evolve_Round) {
            return;
        }

        // EFFECTS
        addAsDaoObserver(
            msg.sender, DukiDaoConstants.SEQ_2_Water_Investors, s_water_2_investors, DukiDaoConstants.MaxInvestorsTotal
        );
        // console2.log("payToInvest", msg.sender, s_dao_bps_count_arr[DukiDaoConstants.SEQ_2_Water_Investors]);

        // INTERACTIONS
        commonDeductFee(DukiDaoTypes.InteractType.In_To_Invest, DukiDaoConstants.BASIC_INVEST_AMOUNT);
    }

    /**
     *
     */
    function claim7Love_WorldDukiInActionFairDrop() external {
        uint256 claimedRound = s_alm_world_7_dukiClaimers[msg.sender];
        if (claimedRound >= s_dao_evolve_round) {
            // console2.log("claim1_AlmDukiInActionFairDrop already claimed", msg.sender, claimedRound, s_dao_evolve_round);
            revert DukiDaoTypes.ClaimedCurrentRoundAlreadyError();
        }

        bool isHuman = isZkProvedHuman(msg.sender);
        if (!isHuman) {
            // console2.log("claim1_AlmDukiInActionFairDrop not zk proved human", msg.sender);
            revert DukiDaoTypes.NotZkProvedHuman();
        }

        DukiDaoTypes.DaoFairDrop storage fairDrop = s_dao_fair_drop_arr[DukiDaoConstants.SEQ_7_Heaven_ALM_DukiInAction];

        if (fairDrop.unitNumber <= 0) {
            // console2.log("claim1_AlmDukiInActionFairDrop no distribution unit left", msg.sender);
            revert DukiDaoTypes.NoDistributionUnitLeft();
        }

        // EFFECTS
        s_alm_world_7_dukiClaimers[msg.sender] = s_dao_evolve_round;
        fairDrop.unitNumber -= 1;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = IERC20(s_stableCoin).transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        emit DukiDaoTypes.DukiInAction(
            msg.sender,
            DukiDaoTypes.InteractType.Out_Claim_As_Duki4World,
            s_dao_evolve_round,
            fairDrop.unitAmount,
            fairDrop.unitNumber,
            block.timestamp,
            ""
        );
    }

    function claim6Love_NationDukiInActionFairDrop() external {
        revert DukiDaoTypes.NotSupported(
            "A ZK-human backed by a challengeable authority. This authority should embrace freedom, welcome criticism, and excel in its duty to serve the people who empower it."
        );
    }

    function claim5Love_CommunityLotteryFairDrop() external {
        // CHECKS
        DukiDaoTypes.CommunityParticipation memory participation = s_community_5_Participants[msg.sender];

        if (participation.participantNo == 0) {
            // console2.log("claim3_CommunityLotteryDrop not in lottery community", msg.sender);
            revert DukiDaoTypes.NotQualifiedForClaim(DukiDaoConstants.SEQ_5_Fire_Community_Participants);
        }

        if (participation.participantNo != s_community_lucky_participant_no) {
            revert DukiDaoTypes.NotCommunityLotteryWinner();
        }

        if (participation.luckyClaimedRound >= s_dao_evolve_round) {
            // console2.log(
            //     "claim3_CommunityLotteryDrop already claimed",
            //     msg.sender,
            //     participation.luckyClaimedRound,
            //     s_dao_evolve_round
            // );
            revert DukiDaoTypes.ClaimedCurrentRoundAlreadyError();
        }

        DukiDaoTypes.DaoFairDrop memory fairDrop =
            s_dao_fair_drop_arr[DukiDaoConstants.SEQ_5_Fire_Community_Participants];
        if (fairDrop.unitNumber <= 0) {
            // console2.log("claim3_CommunityLotteryDrop no distribution unit left", msg.sender);
            revert DukiDaoTypes.NoDistributionUnitLeft();
        }

        uint256 maxClaimAmount = participation.participantAmount * 1000;
        uint256 claimAmount = maxClaimAmount > fairDrop.unitAmount ? fairDrop.unitAmount : maxClaimAmount;

        // EFFECTS
        s_dao_fair_drop_arr[DukiDaoConstants.SEQ_5_Fire_Community_Participants].unitNumber -= 1;
        s_community_5_Participants[msg.sender].luckyClaimedRound = s_dao_evolve_round;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = IERC20(s_stableCoin).transfer(msg.sender, claimAmount);
        if (!success) {
            revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.Out, msg.sender, claimAmount);
        }
        // console2.log("claim3_CommunityLotteryDrop", msg.sender, fairDrop.unitAmount);

        emit DukiDaoTypes.DukiInAction(
            msg.sender,
            DukiDaoTypes.InteractType.Out_Claim_As_CommunityLottery,
            s_dao_evolve_round,
            fairDrop.unitAmount,
            1,
            block.timestamp,
            ""
        );
    }

    function claim4Love_DukiInfluencerFairDrop() external {
        common_claim(
            DukiDaoTypes.InteractType.Out_Claim_As_DukiInfluencer,
            DukiDaoConstants.SEQ_4_Thunder_DukiInfluencers,
            s_thunder_4_duki_influencers
        );
    }

    function claim3Love_ContributorFairDrop() external {
        common_claim(
            DukiDaoTypes.InteractType.Out_Claim_As_Contributor,
            DukiDaoConstants.SEQ_3_Wind_Contributors,
            s_wind_3_contributors
        );
    }

    function claim2Love_InvestorFairDrop() external {
        common_claim(
            DukiDaoTypes.InteractType.Out_Claim_As_Investor, DukiDaoConstants.SEQ_2_Water_Investors, s_water_2_investors
        );
    }

    function claim1Love_MaintainerFairDrop() external {
        common_claim(
            DukiDaoTypes.InteractType.Out_Claim_As_Maintainer,
            DukiDaoConstants.SEQ_1_Mountain_Maintainers,
            s_mountain_1_maintainers
        );
    }

    function claim0Love_FounderFairDrop() external {
        common_claim(
            DukiDaoTypes.InteractType.Out_Claim_As_Founder, DukiDaoConstants.SEQ_0_Earth_Founders, s_earth_0_founders
        );
    }

    function common_claim(
        DukiDaoTypes.InteractType interactType,
        uint256 roleSeq,
        mapping(address => uint256 claimedEvolveNum) storage claimMap
    ) internal {
        if (msg.sender == address(0)) {
            revert DukiDaoTypes.ZeroAddressError();
        }

        uint256 claimedRound = claimMap[msg.sender];
        uint256 currentEvolveAge = s_dao_evolve_round;

        if (claimedRound == 0) {
            // console2.log("common_claim is not qualified", msg.sender, claimedRound);
            revert DukiDaoTypes.NotQualifiedForClaim(roleSeq);
        }

        if (claimedRound == currentEvolveAge) {
            // console2.log("common_claim already claimed", msg.sender, claimedRound, currentEvolveAge);
            revert DukiDaoTypes.ClaimedCurrentRoundAlreadyError();
        }

        DukiDaoTypes.DaoFairDrop storage fairDrop = s_dao_fair_drop_arr[roleSeq];
        if (fairDrop.unitNumber <= 0) {
            // console2.log("error: common_claim no distribution unit left", msg.sender);
            revert DukiDaoTypes.NoDistributionUnitLeft();
        }

        // EFFECTS
        fairDrop.unitNumber -= 1;
        claimMap[msg.sender] = currentEvolveAge;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // console2.log("common_claim", msg.sender, currentEvolveAge, fairDrop.unitAmount);

        // INTERACTIONS
        bool success = IERC20(s_stableCoin).transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        emit DukiDaoTypes.DukiInAction(
            msg.sender, interactType, currentEvolveAge, fairDrop.unitAmount, 1, block.timestamp, ""
        );
    }

    function commonDeductFee(DukiDaoTypes.InteractType interactType, uint256 requiredMoney) internal {
        bool success = IERC20(s_stableCoin).transferFrom(msg.sender, address(this), requiredMoney);

        // console2.log("CoinReceived, requiredMoney from", success, requiredMoney);
        if (success) {
            emit DukiDaoTypes.DukiInAction(
                msg.sender, interactType, s_dao_evolve_round, requiredMoney, 1, block.timestamp, ""
            );
        } else {
            // console2.log("TransferFailed:TransferFailed");
            revert DukiDaoTypes.TransferFailed(DukiDaoTypes.CoinFlowType.In, msg.sender, requiredMoney);
        }
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable { }

    modifier maintainerOnly() {
        if (s_mountain_1_maintainers[msg.sender] == 0) revert DukiDaoTypes.OnlyMaintainerOrAutomationCanCall();
        _;
    }

    modifier maintainerOrAutomationOnly() {
        if (
            s_mountain_1_maintainers[msg.sender] == 0
                && (automationRegistry != address(0) && msg.sender != automationRegistry)
        ) {
            revert DukiDaoTypes.OnlyMaintainerOrAutomationCanCall();
        }
        _;
    }

    /**
     * @notice Updates the minimum wait time between evolution attempts
     * @param newWaitTime The new minimum wait time in seconds
     */
    function setMinWaitBetweenEvolutions(uint256 newWaitTime) external maintainerOnly {
        s_minWaitBetweenEvolutions = newWaitTime;
    }

    /**
     * @notice Updates the randomness request deadline
     * @param newDeadline The new deadline in seconds
     */
    function setRandomnessRequestDeadline(uint256 newDeadline) external maintainerOnly {
        s_randomnessRequestDeadline = newDeadline;
    }

    /**
     * @notice Sets the automation registry address
     * @param _automationRegistry The address of the automation registry
     */
    function setAutomationRegistry(address _automationRegistry) external maintainerOnly {
        automationRegistry = _automationRegistry;
    }

    function tryAbortDaoEvolution() external maintainerOnly {
        s_lastRandomnessWillTimestamp = 0;
    }

    /**
     * @notice Function for ChainLink Automation to call on a schedule
     * @dev This is a time-based function that requests randomness from Anyrand
     * @return success Whether the randomness request was successful
     */
    function requestDaoEvolution(uint256 callbackGasLimit)
        external
        payable
        maintainerOrAutomationOnly
        returns (uint256)
    {
        // Check if minimum wait time has passed since the last callback
        if (s_lastRandomnessWillCallbackTimestamp > 0) {
            if (block.timestamp < s_lastRandomnessWillCallbackTimestamp + s_minWaitBetweenEvolutions) {
                revert DukiDaoTypes.MustWaitBetweenEvolutions(
                    s_lastRandomnessWillCallbackTimestamp, s_minWaitBetweenEvolutions, block.timestamp
                );
            }
        }

        uint256 balance = IERC20(s_stableCoin).balanceOf(address(this));
        if (balance < DukiDaoConstants.DAO_START_EVOLVE_AMOUNT) {
            // console2.log(
            //     "balance < DukiDaoConstants.DAO_START_EVOLVE_AMOUNT, skip evolveDaoThenDistribute", balance, DukiDaoConstants.DAO_START_EVOLVE_AMOUNT
            // );
            revert DukiDaoTypes.InsufficientBalance(balance, DukiDaoConstants.DAO_START_EVOLVE_AMOUNT);
        }

        // Only proceed if there's no pending request
        if (s_lastRandomnessWillTimestamp > 0) {
            revert DukiDaoTypes.DaoEvolutionInProgress();
        }

        // Calculate request price
        (uint256 requestPrice,) = IAnyrand(s_anyrand).getRequestPrice(callbackGasLimit);

        if (msg.value < requestPrice) {
            revert DukiDaoTypes.InsufficientPayment(msg.value, requestPrice);
        }

        if (msg.value > requestPrice) {
            (bool success,) = msg.sender.call{ value: msg.value - requestPrice }("");
            if (!success) {
                revert DukiDaoTypes.RefundFailed();
            }
        }

        // Calculate deadline based on configurable parameter
        uint256 deadline = block.timestamp + s_randomnessRequestDeadline;

        // Request randomness only once
        uint256 willId = IAnyrand(s_anyrand).requestRandomness{ value: requestPrice }(deadline, callbackGasLimit);

        // Update state
        s_lastRandomnessWillId = willId;
        s_lastRandomnessWillTimestamp = block.timestamp;

        emit DukiDaoTypes.DaoEvolutionWilling(willId);
        return willId;
    }

    /**
     * @notice Receive random number from the Anyrand service
     * @param requestId The identifier for the original randomness request
     * @param randomNumber The random value provided
     */
    function receiveRandomness(uint256 requestId, uint256 randomNumber) external override {
        // CHECKS
        if (msg.sender != s_anyrand) {
            revert OnlyAnyrandCanCall();
        }

        // Ensure this is the request we're expecting
        if (requestId != s_lastRandomnessWillId) {
            revert UnknownWillId(requestId, s_lastRandomnessWillId);
        }

        if (s_lastRandomnessWillTimestamp <= 0) {
            revert NoPendingRandomnessWill();
        }

        evolveDaoAndDivideLove(randomNumber);
    }

    function evolveDaoAndDivideLove(uint256 randomNumber) internal {
        uint256 balance = IERC20(s_stableCoin).balanceOf(address(this));

        if (balance < DukiDaoConstants.DAO_START_EVOLVE_AMOUNT) {
            // console2.log(
            //     "balance < DukiDaoConstants.DAO_START_EVOLVE_AMOUNT, skip evolveDaoThenDistribute", balance, DukiDaoConstants.DAO_START_EVOLVE_AMOUNT
            // );
            revert DukiDaoTypes.InsufficientBalance(balance, DukiDaoConstants.DAO_START_EVOLVE_AMOUNT);
        }

        uint256 totalParticipants = s_dao_bps_count_arr[DukiDaoConstants.SEQ_5_Fire_Community_Participants];
        if (totalParticipants <= 0) {
            revert DukiDaoTypes.NoParticipants();
        }

        uint256 luckyNumber = (randomNumber % totalParticipants) + 1;
        uint256 distributionAmount = balance - DukiDaoConstants.DAO_EVOLVE_LEFT_AMOUNT;

        // EFFECTS
        s_lastRandomnessWillCallbackTimestamp = block.timestamp;
        s_lastRandomnessWillTimestamp = 0;

        s_dao_evolve_round += 1;
        s_community_lucky_participant_no = luckyNumber;

        DukiDaoTypes.DaoFairDrop[8] memory daoFairDrops;
        //  dukiInAction
        uint256[8] memory bpsUnitNumArr = s_dao_bps_count_arr;
        uint256[8] memory bpsArr = s_dao_bps_arr; 

        // iterate over baguaDaoUnitTotals
        for (uint256 i = 0; i < 8; i++) {
            uint256 bpsAmount = (bpsArr[i] * distributionAmount) / DukiDaoConstants.BPS_PRECISION;
            uint256 bpsUnitNum = bpsUnitNumArr[i];

            if (DukiDaoConstants.SEQ_7_Heaven_ALM_DukiInAction == i) {
                uint256 almUnitTotalNum = bpsAmount / DukiDaoConstants.DukiInAction_StableCoin_Claim_Amount;
                daoFairDrops[i] = DukiDaoTypes.DaoFairDrop(
                    DukiDaoConstants.DukiInAction_StableCoin_Claim_Amount, almUnitTotalNum, almUnitTotalNum
                );
            } else if (DukiDaoConstants.SEQ_5_Fire_Community_Participants == i) {
                if (bpsUnitNum <= 0) {
                    // no one join the community , sad story
                    continue;
                }
                daoFairDrops[i] = DukiDaoTypes.DaoFairDrop(bpsAmount, 1, 1);
            } else {
                if (bpsUnitNum <= 0) {
                    continue;
                }
                uint256 unitAmount = bpsAmount / bpsUnitNum;
                daoFairDrops[i] = DukiDaoTypes.DaoFairDrop(unitAmount, bpsUnitNum, bpsUnitNum);
            }
        }

        // Set the values in batch
        s_dao_fair_drop_arr = daoFairDrops;

        emit DukiDaoTypes.DaoEvolutionManifestation(
            s_dao_evolve_round, s_lastRandomnessWillId, randomNumber, luckyNumber, daoFairDrops
        );
    }
}
