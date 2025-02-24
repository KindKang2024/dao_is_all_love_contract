// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISharedStructs.sol";
import { IUnstoppableDukiDao } from "./IUnstoppableDukiDao.sol";

abstract contract UnstoppableDukiDaoConstants {
  uint256 constant SEQ_0_FAIR_DROP_SUMMARY = 0;

  uint256 constant Initial_Evolve_Base_Num = 1; // must be 1 to distinguish from 0 - unexisted
  uint256 constant Initial_Claim_FairDrop_Round = Initial_Evolve_Base_Num; // must be 1 to distinguish from 0 - unexisted

  //  dao is love; love be ye way to do marketing
  uint256 constant SEQ_1_Heaven_ALM_DukiInAction = 1; //wallet must have a unstoppable domain , pretends to be a unique human being
  uint256 constant SEQ_2_Lake_Nation = 2; // wallet, for nation
  uint256 constant SEQ_3_Fire_Community = 3; // Wallet, all unstoppable subscribers including lifetime subscription, early supporters ; share lattery, 1/10000 chance to win  , also pay to join
  uint256 constant SEQ_4_Thunder_Builders = 4; //outside builder

  // private love - survive and exist sin
  uint256 constant SEQ_5_Wind_Contributors = 5; //
  uint256 constant SEQ_6_Water_Investors = 6;
  // Wallet, Lifetime subscription
  uint256 constant SEQ_7_Mountain_Maintainers = 7; // Wallet,  need survive first operations
  uint256 constant SEQ_8_Earth_Creators = 8; // wallet, need be created

  // do not take this numbers too seriously. Without trust, there are always ways to cheat; yes, everything.
  uint256 constant BPS_PRECISION = 10000;

  // 1/10000 chance to win, rotate number [1-10000], if there is 10001, it got 1 again, 10002 got 2
  // if sample number is 1, max winners is 2; if number > 30000, only the first two claimers can get the reward
  uint256 constant MaxLotteryParticipantNumber = 10000;
  uint256 constant MaxLifetimeSupportersTotal = 369; // telsa 369

  string constant UNS_TEST_DOMAIN = "uns-devtest-";
  string constant UNS_TLD = "unstoppable";
  uint256 constant MaxEarlyDukiSupportersCnt = 500;

  uint64 constant LIFE_TIME_EXPIRE_SECONDS = type(uint64).max;

  uint256 constant DAO_START_EVOLVE_AMOUNT = 100 * ONE_DOLLAR_BASE;
  uint256 constant DAO_EVOLVE_LEFT_AMOUNT = 8 * ONE_DOLLAR_BASE;

  uint256 constant MIN_DukiInAction_Bps = 250;
  uint256 constant Initial_1_MIN_DukiInAction_Bps = 1000; // [2.5%- ]  10% - just for all lives/wallets that have a  unstoppable domain (human unique proof is needed serious DukiInAction in AllLivesMatter.World)

  // s_baguaDaoPcts[9] = [BAGUA_PCT_PRECISION, MIN_DukiInAction_Pct ];
  uint256 constant Min_Community_Lottery_Bps = 500;
  uint256 constant Initial_2_Community_Lottery_Bps = 1000; // 15% avenues goes to lottery, 1/10000 chance to win, max 2, subscribe to join or pay to join
  // even if there are more than 3 winners, only the first 3 can claim the rewards;
  // first come, first claim; it means 3 principles - kindnessFirst, fairnessAwlays, and dukiInAction
  uint256 constant Max_Lottery_Winner_Per_Round = 3;

  uint256 constant Initial_Early_Lifetime_Subscription_Fee =
    30 * Initial_Subscription_Yearly_Fee;

  uint256 constant Min_EarlyLifeTimeSupporters_Bps = 2000; // 10% for lifetime subscription, early supporters
  uint256 constant Initial_3_EarlyLifeTimeSupporters_Bps = 2000; // 20% for lifetime subscription, early supporters

  uint256 constant Initial_4_or_5_ZERO = 0; // later may change

  uint256 constant Initial_Zero = 0;
  uint256 constant Lifetime_Subscription_Represent_Value = 0;
  uint256 constant Lifetime_Subscription_Needed_Min_Sub_Years = 30;

  uint256 constant Min_Investors_Bps = 1000;
  // 10% avnues  100$ x 100 = 30 000$  -> max total project value = 300 000$ 3 KindnessFirst&FairnessAlways&DukiInActioin
  // high risk and do not take the rewards too seriously, main purpose is for fun and advocation
  uint256 constant Initial_6_Investors_Bps = 1000;

  uint256 constant Min_SurvivalMaintainers_Bps = 3000;
  uint256 constant Initial_7_SurvivalMaintainers_Bps = 4000; // 40% , , without survival, there is no existence, no sin,no story, no life, no death, no love, no dao

  uint256 constant Max_Creators_Bps = 1000;
  uint256 constant Min_Creators_Bps = 250;
  uint256 constant Stable_Coin_Decimals = 6; // USDT
  uint256 constant Min_StableCoin_Claim_Amount =
    1 * 10 ** (Stable_Coin_Decimals - 1); // 0.1 USD
  uint256 constant Alm_DukiInAction_StepIncr_Num = 100;

  // uint256 public s_investorsTotal;
  uint256 constant MaxInvestorsTotal = 100; // >=10%  $300

  uint256 constant Initial_8_Creators_Bps = 1000; // 10%  all lives are creators and builders, you just need works to manifest the dao/love; love be ye way to create sth from  void

  // FEES
  // 12 coin per year, may change later
  uint256 constant ONE_DOLLAR_BASE = 10 ** Stable_Coin_Decimals;
  uint256 constant Initial_Subscription_Yearly_Fee = 12 * ONE_DOLLAR_BASE;
  uint256 constant Initial_Lottery_Entry_Fee = 10 * ONE_DOLLAR_BASE;
  uint256 constant Initial_Investment_Fee = 100 * ONE_DOLLAR_BASE;
  bool[9] Nine_False_Array =
    [false, false, false, false, false, false, false, false, false];
}
