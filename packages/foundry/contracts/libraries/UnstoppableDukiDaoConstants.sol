// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISharedStructs.sol";
import { IUnstoppableDukiDao } from "./IUnstoppableDukiDao.sol";

abstract contract UnstoppableDukiDaoConstants {
    uint256 constant BASIC_INVEST_AMOUNT = 100 * ONE_DOLLAR_BASE; // must be 1 to distinguish from 0 - unexisted
    uint256 constant Initial_Evolve_Round = 1; // must be 1 to distinguish from 0 - unexisted

    // do not take this numbers too seriously. Without trust, there are always ways to cheat; yes, everything.
    uint256 constant BPS_PRECISION = 10000;

    // 1/10000 chance to win, rotate number [1-10000], if there is 10001, it got 1 again, 10002 got 2

    uint256 constant LUCK_NUMBER_DENSITY_PER_ROUND = 1000;

    uint256 constant MaxEarlyDukiSupportersCnt = 500;

    uint64 constant LIFE_TIME_EXPIRE_SECONDS = type(uint64).max;

    uint256 constant DAO_START_EVOLVE_AMOUNT = 100 * ONE_DOLLAR_BASE;
    uint256 constant DAO_EVOLVE_LEFT_AMOUNT = 8 * ONE_DOLLAR_BASE;


    uint256 constant Initial_0_Founders_Bps = 250; // [2.5% ]  
    uint256 constant Initial_1_Maintainers_Bps = 3000; // hopes it cover the cost and make it survive
    uint256 constant Initial_2_Investors_Bps = 2500; // 25%  max-cap $369*100 for 25% 
    uint256 constant Initial_3_Contributors_Bps = 750; // 

    uint256 constant Initial_4_Builders_Bps = 500;  
    uint256 constant Initial_5_Community_Bps = 2000;
    uint256 constant Initial_6_ALM_Nation_DukiInAction_Bps = 0; // 0 for now, need nation back up the human proof 
    uint256 constant Initial_7_ALM_World_DukiInAction_Bps = 1000; //  serious business should be 1%-2.5%.  here 10% since this is a poc and advocate
    uint256 constant MIN_DukiInAction_Bps = 100; // 1%

    // here use the order start from KUN, like how love evolves from earth to heaven, play nicely with binary its form. It is natural to think so, we have to love the ego will first.
    // Also, I do not think it violates the order of traditional Chinese culture. The love for all lives is the highest form I could imagine. It is no 1 from that perspective.
    uint256 constant SEQ_0_Earth_Founders = 0;
    uint256 constant SEQ_1_Mountain_Maintainers = 1;
    uint256 constant SEQ_2_Water_Investors = 2;
    uint256 constant SEQ_3_Wind_Contributors = 3;
    uint256 constant SEQ_4_Thunder_DukiBuilders = 4;
    uint256 constant SEQ_5_Community_Participants = 5;
    uint256 constant SEQ_6_DukiInAction_ALM_Nation = 6; // hope it become as tax to all lives in that nation
    uint256 constant SEQ_7_DukiInAction_ALM_World = 7;

    uint256 constant LotteryMaxLuckyNumber = 2000;

    uint256 constant Stable_Coin_Decimals = 6; // USDT
    // A zero-knowledge proof Of human verification backed with authority and freely challengeable is needed .
    //  WorldId is also not enough. https://x.com/OrdKindKang/status/1835352385423814858
    //  Current we just assume the wallet is human. and check the wallet has at least 10 stable coin inside
    uint256 constant DukiInAction_StableCoin_Claim_Amount = 15 * 10 ** (Stable_Coin_Decimals - 3);

    // minimum stable coin amount to claim DUKI
    uint256 constant Min_DUKI_Claim_StableCoin_Prerequisite_Amount = 10 ** Stable_Coin_Decimals;

    uint256 constant MaxInvestorsTotal = 369; // telsa 369

    // FEES
    // 12 coin per year, may change later
    uint256 constant ONE_DOLLAR_BASE = 10 ** Stable_Coin_Decimals;
    // bool[9] Nine_False_Array = [false, false, false, false, false, false, false, false, false];
}
