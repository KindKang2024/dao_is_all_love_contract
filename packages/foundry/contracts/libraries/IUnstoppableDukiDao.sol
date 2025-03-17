// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISharedStructs.sol";
import { IBaguaDukiDao } from "./IBaguaDukiDao.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUnstoppableDukiDao is ISharedStructs {
    function baguaDaoUnitCountArr() external view returns (uint256[8] memory);
    function baguaDaoFairDropArr() external view returns (DaoFairDrop[8] memory);
    function baguaDaoBpsArr() external view returns (uint256[8] memory);

    function buaguaDaoAgg4Me(address user) external view returns (BaguaDaoAgg memory);

    function connectDaoToKnow(
        bytes16 diviUuid,
        bytes32 diviWillHash,
        bytes16 diviWillAnswer,
        uint256 willPowerAmount
    ) external;

    // after verified the divination, the user can vow to the dao
    function vowDaoManifestation(
        bytes16 diviUuid,
        KnownStatus knownStatus
    ) external;



    function connectDaoToInvest() external;

    // the following function needs to verified by the founder or maintainer,
    // ultimately all determined by the founder's will, I do not believe that all need to be decentralized.
    // That means no one is really has accountability for any thing, no body is in charge in the end.

    // maybe later
    // function requestToVerifyAsContributor() external;
    // function requestToVerifyAsMaintainer() external;
    // function requestToVerifyAsDukiInActionBuilder() external;

    // function approveAsContributor(address requestor) external;
    // function approveAsMaintainer(address requestor) external;
    // function approveAsDukiInActionBuilder(address requestor) external;

    function requestDaoEvolution(uint256 callbackGasLimit) external payable returns (uint256);
    function tryAbortDaoEvolution() external;

    // Claim functions
    function claim7Love_WorldDukiInActionFairDrop() external;
    function claim6Love_NationDukiInActionFairDrop() external;
    function claim5Love_CommunityLotteryFairDrop() external;
    function claim4Love_BuilderFairDrop() external;
    function claim3Love_ContributorFairDrop() external;
    function claim2Love_InvestorFairDrop() external;
    function claim1Love_MaintainerFairDrop() external;
    function claim0Love_FounderFairDrop() external;
}
