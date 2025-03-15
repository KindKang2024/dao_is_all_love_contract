// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Imaginary Human Proof Interface , backed by  true authority using zk-proof 
///  the true authority can be challenged by anyone and must coordinate with the world to guard the integrity of the proof

/// for duki in action, we need this. 
/// And We should only make the nation information avaible to everyone for better accountability
/// since humans are already divided by nation spirtually and physically. 
interface IZkHumanRegistry {

    function isZkProvedHuman(address user)
        external
        view
        returns (bool);

}
