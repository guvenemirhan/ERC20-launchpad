// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

struct Presale {
    address currency;
    uint256 presaleRate;
    uint256 softcap;
    uint256 hardcap;
    uint256 minBuy;
    uint256 maxBuy;
    uint256 liquidityRate;
    uint256 listingRate;
    uint256 startTime;
    uint256 endTime;
    uint256 lockEndTime;
    bool isVesting;
    bool isLock;
    bool refund;
    bool autoListing;
}

struct Vesting {
    uint256 tge;
    uint256 cliff;
    uint256 release;
    uint256 startTime;
}

struct Contributor {
    uint256 totalContributed;
    uint256 claimable;
    uint256 claimed;
    uint256 released;
    bool tgeClaimed;
}
