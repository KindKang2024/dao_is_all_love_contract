//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./libraries/IBaguaDukiDao.sol";
// import "forge-std/console2.sol"; // For Foundry

import "./dependencies/IRandomiserCallbackV3.sol";
import "./dependencies/IAnyrand.sol";
import "./dependencies/IZkHumanRegistry.sol";

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
    IUnstoppableDukiDao,
    IRandomiserCallbackV3
{
    // Remove AutomationCompatibleInterface

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
    DaoFairDrop[8] s_dao_fair_drop_arr;

    uint256 private s_dao_claimed_amount;

    uint256 s_investment_3_fee;

    uint256 public s_community_lucky_participant_no;

    mapping(address => uint256 claimedEvolveNum) s_earth_0_founders;

    mapping(address => uint256 claimedEvolveNum) s_mountain_1_maintainers;

    mapping(address => uint256 claimedEvolveNum) s_water_2_investors;

    mapping(address => uint256 claimedEvolveNum) s_wind_3_contributors; //
    mapping(address => uint256 claimedEvolveNum) s_thunder_4_duki_Builders;

    mapping(address => CommunityParticipation) s_community_5_Participants;

    mapping(address => mapping(bytes16 => Divination)) s_dao_love_connections;

    mapping(address => uint256 claimedEvolveNum) s_alm_nation_6_supporters; // all people inside one country

    mapping(address => uint256 claimedEvolveNum) s_alm_world_7_dukiClaimers; // requires to be a unique human being, concept now; 


    // Keep track of authorized Automation addresses
    address public automationRegistry;

    // just a slot , currently not in use IZkHumanRegistry
    address public humanZkpRegistry;


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
        return IERC20(s_stableCoin).balanceOf(user) > ONE_DOLLAR_BASE;
    }

    // Authorization function for contract upgrades
    function _authorizeUpgrade(address newImplementation) internal pure override {
        require(newImplementation != address(0), "New implementation cannot be zero address");
    }

    // function initialize(NetworkConfig memory config) public {
    function initialize(NetworkConfig memory config) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);

        if (config.stableCoin == address(0)) revert ZeroAddressError(); // Add this check
        if (config.anyrand == address(0)) revert ZeroAddressError(); // Check anyrand address

        s_investment_3_fee = 1000 * ONE_DOLLAR_BASE;
        s_dao_evolve_round = Initial_Evolve_Round; //  monotonic increasing. when it evolves, it will be 2, so could be different from others intial claim round = 1
        s_dao_born_seconds = block.timestamp;

        s_stableCoin = config.stableCoin;
        s_anyrand = config.anyrand;

        // Initialize time parameters with defaults
        s_minWaitBetweenEvolutions = 7 days;
        s_randomnessRequestDeadline = 300; // 5 minutes

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
            s_earth_0_founders[config.creators[i]] = Initial_Evolve_Round;
        }

        s_dao_bps_count_arr[SEQ_0_Earth_Founders] = config.creators.length;

        uint256[8] memory emptyArr;
        for (uint256 i = 0; i < config.maintainers.length; i++) {
            if (config.maintainers[i] == address(0)) revert ZeroAddressError();
            s_mountain_1_maintainers[config.maintainers[i]] = Initial_Evolve_Round;
        }
        s_dao_bps_count_arr[SEQ_1_Mountain_Maintainers] = config.maintainers.length;

        emit BaguaDukiDaoBpsChanged(emptyArr, s_dao_bps_arr, block.timestamp);
    }

    function totalStableCoin() external view returns (uint256) {
        return IERC20(s_stableCoin).balanceOf(address(this));
    }

    function baguaDaoUnitCountArr() external view returns (uint256[8] memory) {
        return s_dao_bps_count_arr;
    }

    function baguaDaoFairDropArr() external view returns (DaoFairDrop[8] memory) {
        return s_dao_fair_drop_arr;
    }

    function baguaDaoBpsArr() external view override returns (uint256[8] memory) {
        return s_dao_bps_arr;
    }

    function buaguaDaoAgg4Me(address user) external view override returns (BaguaDaoAgg memory) {
        CommunityParticipation memory participation = s_community_5_Participants[user];

        uint256[8] memory userClaimedRoundArr = [
            s_earth_0_founders[user],
            s_mountain_1_maintainers[user],
            s_water_2_investors[user],
            s_wind_3_contributors[user],
            s_thunder_4_duki_Builders[user],
            participation.luckyClaimedRound,
            s_alm_nation_6_supporters[user],
            s_alm_world_7_dukiClaimers[user]
        ];

        uint256 currentEvolveRound = s_dao_evolve_round;

        uint256 stableCoinBalance = IERC20(s_stableCoin).balanceOf(user);
        bool isHuman = stableCoinBalance > ONE_DOLLAR_BASE;


        bool[8] memory userQualifiedArr = [
            userClaimedRoundArr[0] > 0 && userClaimedRoundArr[0] < currentEvolveRound,
            userClaimedRoundArr[1] > 0 && userClaimedRoundArr[1] < currentEvolveRound,
            userClaimedRoundArr[2] > 0 && userClaimedRoundArr[2] < currentEvolveRound,
            userClaimedRoundArr[3] > 0 && userClaimedRoundArr[3] < currentEvolveRound,
            userClaimedRoundArr[4] > 0 && userClaimedRoundArr[4] < currentEvolveRound,
            userClaimedRoundArr[5] > 0 && userClaimedRoundArr[5] < currentEvolveRound,
            userClaimedRoundArr[6] > 0 && userClaimedRoundArr[6] < currentEvolveRound,
            // userClaimedRoundArr[7] < currentEvolveRound && isZkProvedHuman(user)
            userClaimedRoundArr[7] < currentEvolveRound && isHuman
        ];

        return BaguaDaoAgg(
            s_dao_evolve_round,
            s_dao_born_seconds,
            s_dao_claimed_amount,
            stableCoinBalance,
            s_dao_bps_arr,
            s_dao_bps_count_arr,
            s_dao_fair_drop_arr,
            s_community_lucky_participant_no,
            userQualifiedArr,
            participation
        );
    }

    /**
     *
     */
    function connectDaoToDivine(
        bytes16 diviUuid,
        bytes16 diviWillHash,
        bytes16 diviWillAnswer,
        uint256 willPowerAmount // money amount
    ) external {
        // CHECKS
        if (msg.sender == address(0)) {
            revert ZeroAddressError();
        }

        // money must amount must > 0
        if (willPowerAmount <= 0) {
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
                CommunityParticipation(s_dao_bps_count_arr[SEQ_5_Community_Participants], willPowerAmount, 0);
        } else {
            s_community_5_Participants[msg.sender].participantAmount += willPowerAmount;
        }
        commonDeductFee(InteractType.In_To_Divine, willPowerAmount);

        // save the divination info
        s_dao_love_connections[msg.sender][diviUuid] = Divination(
            KnownStatus.Unknown,
            diviWillHash,
            diviWillAnswer,
            willPowerAmount
        );
        emit ConnectDaoEvent(msg.sender, diviUuid, diviWillHash, block.timestamp);

    }

  

    // after verified the divination, the user can vow to the dao
    function vowDaoDivination(
        bytes16 diviUuid,
        KnownStatus knownStatus
    ) external {
        if (knownStatus == KnownStatus.Unknown) {
            revert InvalidKnownStatus();
        }

        // save the vow info
        s_dao_love_connections[msg.sender][diviUuid].knownStatus = knownStatus;
        emit VowDaoEvent(msg.sender, diviUuid, knownStatus, block.timestamp);
    }



    function isStructExist(CommunityParticipation memory qualification) internal pure returns (bool) {
        return qualification.participantNo > 0;
    }

    /**
     * a way to support, at least 10% of the total project revenue will be shared with the investors
     */
    function connectDaoToInvest() external {
        // CHECKS
        if (s_dao_bps_count_arr[SEQ_2_Water_Investors] >= MaxInvestorsTotal) {
            revert InvestorsFull();
        }

        if (s_water_2_investors[msg.sender] >= Initial_Evolve_Round) {
            revert AlreadyInvested();
        }

        // EFFECTS
        s_dao_bps_count_arr[SEQ_2_Water_Investors] += 1;
        s_water_2_investors[msg.sender] = Initial_Evolve_Round;
        // console2.log("payToInvest", msg.sender, s_dao_bps_count_arr[SEQ_2_Water_Investors]);

        // INTERACTIONS
        commonDeductFee(InteractType.In_To_Invest, BASIC_INVEST_AMOUNT);

    }

    /**
     *
     */
    function claim7Love_WorldDukiInActionFairDrop() external {
        uint256 claimedRound = s_alm_world_7_dukiClaimers[msg.sender];
        if (claimedRound >= s_dao_evolve_round) {
            // console2.log("claim1_AlmDukiInActionFairDrop already claimed", msg.sender, claimedRound, s_dao_evolve_round);
            revert ClaimedCurrentRoundAlreadyError();
        }

        bool isHuman = isZkProvedHuman(msg.sender);
        if (!isHuman) {
            // console2.log("claim1_AlmDukiInActionFairDrop not zk proved human", msg.sender);
            revert NotZkProvedHuman();
        }

        DaoFairDrop storage fairDrop = s_dao_fair_drop_arr[SEQ_7_DukiInAction_ALM_World];

        if (fairDrop.unitNumber <= 0) {
            // console2.log("claim1_AlmDukiInActionFairDrop no distribution unit left", msg.sender);
            revert NoDistributionUnitLeft();
        }

        // EFFECTS
        s_alm_world_7_dukiClaimers[msg.sender] = s_dao_evolve_round;
        fairDrop.unitNumber -= 1;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = IERC20(s_stableCoin).transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        emit DukiInAction(
            msg.sender,
            InteractType.Out_Claim_As_Duki4World,
            s_dao_evolve_round,
            fairDrop.unitAmount,
            fairDrop.unitNumber,
            block.timestamp
        );
    }

    function claim6Love_NationDukiInActionFairDrop() external {
        revert NotSupported(
            "Maybe we need true authority to back the ZKP human proof for all of this in action. This authority should embrace freedom, welcome criticism, and excel in their duty to work for the people who empower them."
        );
    }

    function claim5Love_CommunityLotteryFairDrop() external {
        // CHECKS
        CommunityParticipation memory participation = s_community_5_Participants[msg.sender];

        if (participation.participantNo == 0) {
            // console2.log("claim3_CommunityLotteryDrop not in lottery community", msg.sender);
            revert NotQualifiedForClaim(InteractType.Out_Claim_As_CommunityLottery);
        }

        if (participation.participantNo != s_community_lucky_participant_no) {
            revert NotCommunityLotteryWinner();
        }

        if (participation.luckyClaimedRound >= s_dao_evolve_round) {
            // console2.log(
            //     "claim3_CommunityLotteryDrop already claimed",
            //     msg.sender,
            //     participation.luckyClaimedRound,
            //     s_dao_evolve_round
            // );
            revert ClaimedCurrentRoundAlreadyError();
        }

        DaoFairDrop memory fairDrop = s_dao_fair_drop_arr[SEQ_5_Community_Participants];
        if (fairDrop.unitNumber <= 0) {
            // console2.log("claim3_CommunityLotteryDrop no distribution unit left", msg.sender);
            revert NoDistributionUnitLeft();
        }

        uint256 maxClaimAmount = participation.participantAmount * 1000;
        uint256 claimAmount = maxClaimAmount > fairDrop.unitAmount ? fairDrop.unitAmount : maxClaimAmount;

        // EFFECTS
        s_dao_fair_drop_arr[SEQ_5_Community_Participants].unitNumber -= 1;
        s_community_5_Participants[msg.sender].luckyClaimedRound = s_dao_evolve_round;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // INTERACTIONS
        bool success = IERC20(s_stableCoin).transfer(msg.sender, claimAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, claimAmount);
        }
        // console2.log("claim3_CommunityLotteryDrop", msg.sender, fairDrop.unitAmount);

        emit DukiInAction(
            msg.sender,
            InteractType.Out_Claim_As_CommunityLottery,
            s_dao_evolve_round,
            fairDrop.unitAmount,
            1,
            block.timestamp
        );
    }

    function claim4Love_BuilderFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Builder, SEQ_4_Thunder_DukiBuilders, s_thunder_4_duki_Builders);
    }

    function claim3Love_ContributorFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Contributor, SEQ_3_Wind_Contributors, s_wind_3_contributors);
    }

    function claim2Love_InvestorFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Investor, SEQ_2_Water_Investors, s_water_2_investors);
    }

    function claim1Love_MaintainerFairDrop() external {
        common_claim(InteractType.Out_Claim_As_Maintainer, SEQ_1_Mountain_Maintainers, s_mountain_1_maintainers);
    }

    function claim0Love_FounderFairDrop() external {
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
        uint256 currentEvolveAge = s_dao_evolve_round;

        if (claimedRound == 0) {
            // console2.log("common_claim is not qualified", msg.sender, claimedRound);
            revert NotQualifiedForClaim(interactType);
        }

        if (claimedRound == currentEvolveAge) {
            // console2.log("common_claim already claimed", msg.sender, claimedRound, currentEvolveAge);
            revert ClaimedCurrentRoundAlreadyError();
        }

        DaoFairDrop storage fairDrop = s_dao_fair_drop_arr[seq];
        if (fairDrop.unitNumber <= 0) {
            // console2.log("error: common_claim no distribution unit left", msg.sender);
            revert NoDistributionUnitLeft();
        }

        // EFFECTS
        fairDrop.unitNumber -= 1;
        claimMap[msg.sender] = currentEvolveAge;
        s_dao_claimed_amount += fairDrop.unitAmount;

        // console2.log("common_claim", msg.sender, currentEvolveAge, fairDrop.unitAmount);

        // INTERACTIONS
        bool success = IERC20(s_stableCoin).transfer(msg.sender, fairDrop.unitAmount);
        if (!success) {
            revert TransferFailed(CoinFlowType.Out, msg.sender, fairDrop.unitAmount);
        }

        emit DukiInAction(msg.sender, interactType, currentEvolveAge, fairDrop.unitAmount, 1, block.timestamp);
    }

    function commonDeductFee(InteractType interactType, uint256 requiredMoney) internal {
        uint256 allowanceMoney = IERC20(s_stableCoin).allowance(msg.sender, address(this));
        if (allowanceMoney < requiredMoney) {
            // console2.log("InsufficientAllowance: allowance < required", allowanceMoney, requiredMoney);
            revert InsufficientAllowance(interactType, msg.sender, requiredMoney);
        }

        bool success = IERC20(s_stableCoin).transferFrom(msg.sender, address(this), requiredMoney);

        // console2.log("CoinReceived, requiredMoney from", success, requiredMoney);
        if (success) {
            emit DukiInAction(msg.sender, interactType, s_dao_evolve_round, requiredMoney, 1, block.timestamp);
        } else {
            // console2.log("TransferFailed:TransferFailed");
            revert TransferFailed(CoinFlowType.In, msg.sender, requiredMoney);
        }
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable { }

    modifier maintainerOnly() {
        if (s_mountain_1_maintainers[msg.sender] == 0) revert OnlyMaintainerOrAutomationCanCall();
        _;
    }

    modifier maintainerOrAutomationOnly() {
        if (
            s_mountain_1_maintainers[msg.sender] == 0
                && (automationRegistry != address(0) && msg.sender != automationRegistry)
        ) {
            revert OnlyMaintainerOrAutomationCanCall();
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
     * @notice Function for Chainlink Automation to call on a schedule
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
                revert MustWaitBetweenEvolutions(
                    s_lastRandomnessWillCallbackTimestamp, s_minWaitBetweenEvolutions, block.timestamp
                );
            }
        }

        uint256 balance = IERC20(s_stableCoin).balanceOf(address(this));
        if (balance < DAO_START_EVOLVE_AMOUNT) {
            // console2.log(
            //     "balance < DAO_START_EVOLVE_AMOUNT, skip evolveDaoThenDistribute", balance, DAO_START_EVOLVE_AMOUNT
            // );
            revert InsufficientBalance(balance, DAO_START_EVOLVE_AMOUNT);
        }

        // Only proceed if there's no pending request
        if (s_lastRandomnessWillTimestamp > 0) {
            revert DaoEvolutionInProgress();
        }

        // Calculate request price
        (uint256 requestPrice,) = IAnyrand(s_anyrand).getRequestPrice(callbackGasLimit);

        if (msg.value < requestPrice) {
            revert InsufficientPayment(msg.value, requestPrice);
        }

        if (msg.value > requestPrice) {
            (bool success,) = msg.sender.call{ value: msg.value - requestPrice }("");
            if (!success) {
                revert RefundFailed();
            }
        }

        // Calculate deadline based on configurable parameter
        uint256 deadline = block.timestamp + s_randomnessRequestDeadline;

        // Request randomness only once
        uint256 willId = IAnyrand(s_anyrand).requestRandomness{ value: requestPrice }(deadline, callbackGasLimit);

        // Update state
        s_lastRandomnessWillId = willId;
        s_lastRandomnessWillTimestamp = block.timestamp;

        emit DaoEvolutionWilling(willId, block.timestamp);
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

    function evolveDaoAndDivideLove(uint256 randomNumber) public {
        uint256 balance = IERC20(s_stableCoin).balanceOf(address(this));

        if (balance < DAO_START_EVOLVE_AMOUNT) {
            // console2.log(
            //     "balance < DAO_START_EVOLVE_AMOUNT, skip evolveDaoThenDistribute", balance, DAO_START_EVOLVE_AMOUNT
            // );
            revert InsufficientBalance(balance, DAO_START_EVOLVE_AMOUNT);
        }

        uint256 totalParticipants = s_dao_bps_count_arr[SEQ_5_Community_Participants];
        if (totalParticipants <= 0) {
            revert NoParticipants();
        }

        uint256 luckyNumber = (randomNumber % totalParticipants) + 1;
        uint256 distributionAmount = balance - DAO_EVOLVE_LEFT_AMOUNT;

        // EFFECTS
        s_lastRandomnessWillCallbackTimestamp = block.timestamp;
        s_lastRandomnessWillTimestamp = 0;

        s_dao_evolve_round += 1;
        s_community_lucky_participant_no = luckyNumber;

        DaoFairDrop[8] memory daoFairDrops;
        //  dukiInAction
        uint256[8] memory bpsUnitNumArr = s_dao_bps_count_arr;

        // iterate over baguaDaoUnitTotals
        for (uint256 i = 0; i < 8; i++) {
            uint256 bpsAmount = (s_dao_bps_arr[i] * distributionAmount) / BPS_PRECISION;
            uint256 bpsUnitNum = bpsUnitNumArr[i];

            if (SEQ_7_DukiInAction_ALM_World == i) {
                uint256 almUnitTotalNum = bpsAmount / DukiInAction_StableCoin_Claim_Amount;
                daoFairDrops[i] = DaoFairDrop(DukiInAction_StableCoin_Claim_Amount, almUnitTotalNum);
            } else if (SEQ_5_Community_Participants == i) {
                if (bpsUnitNum <= 0) {
                    // no one join the community , sad story
                    continue;
                }
                daoFairDrops[i] = DaoFairDrop(bpsAmount, 1);
            } else {
                if (bpsUnitNum <= 0) {
                    continue;
                }
                uint256 unitAmount = bpsAmount / bpsUnitNum;
                daoFairDrops[i] = DaoFairDrop(unitAmount, bpsUnitNum);
            }
        }

        // Set the values in batch
        s_dao_fair_drop_arr = daoFairDrops;

        emit DaoEvolutionManifestation(
            s_lastRandomnessWillId, randomNumber, luckyNumber, s_dao_evolve_round, daoFairDrops, block.timestamp
        );
    }
}
