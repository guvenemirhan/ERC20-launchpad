// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Vesting, Contributor} from "../interfaces/IPresale.sol";

library VestingLib {
    /**
     * @notice Calculate the claimable token amount for a contributor considering vesting.
     * @dev This function first checks if the TGE (Token Generation Event) amount has been claimed by the contributor.
     * If not, it is added to the claimable amount and subtracted from the total claimable amount of the contributor.
     * It then checks if the vesting start time has been reached. If not, the claimable amount (only TGE amount at this point) is returned.
     * If the vesting start time has been reached, it calculates the current vesting phase based on the time passed since the start time and the duration of a cliff.
     * It then calculates the token amount per phase and the total claimable amount based on the number of phases that have passed since the last claim.
     * The total claimable amount is adjusted if it's larger than the remaining claimable amount of the contributor.
     * Finally, the function updates the total claimed amount of the contributor.
     * @param vesting The vesting data including start time, cliff duration, and release percentage.
     * @param contributor The contributor data including the total claimable amount, the amount already claimed, and the last claimed vesting phase.
     * @return claimable The amount of tokens that can be claimed by the contributor at this point.
     *
     * Requirements:
     * - The current phase must be greater than or equal to the last released phase.
     * - The number of past phases must be greater than 0.
     */
    function calculateClaimableAmount(
        Vesting memory vesting,
        Contributor storage contributor
    ) internal returns (uint256 claimable) {
        if (!contributor.tgeClaimed) {
            contributor.tgeClaimed = true;
            unchecked {
                claimable += (contributor.claimable * vesting.tge) / 100;
                contributor.claimable -= claimable;
            }
        }
        if (block.timestamp < vesting.startTime) {
            return claimable;
        }
        uint256 passingTime = block.timestamp - vesting.startTime;
        uint256 currentPhase = passingTime / vesting.cliff + 1;
        require(currentPhase >= contributor.released, "No new phases");
        uint256 pastPhases;
        unchecked {
            pastPhases = currentPhase - contributor.released;
        }
        require(pastPhases > 0, "");
        uint256 totalPhase = (100 - vesting.tge) / vesting.release;
        uint256 amountPerPhase = contributor.claimable / totalPhase;
        contributor.released = currentPhase;
        unchecked {
            claimable += amountPerPhase * pastPhases;
        }
        claimable = claimable > contributor.claimable - contributor.claimed
            ? contributor.claimable - contributor.claimed
            : claimable;
        unchecked {
            contributor.claimed += claimable;
        }
        return claimable;
    }
}
