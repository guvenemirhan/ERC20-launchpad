import { ethers } from "hardhat";

export const types = {
  Permit: [
    { name: "currency", type: "address" },
    { name: "presaleRate", type: "uint256" },
    { name: "softcap", type: "uint256" },
    { name: "hardcap", type: "uint256" },
    { name: "minBuy", type: "uint256" },
    { name: "maxBuy", type: "uint256" },
    { name: "liquidityRate", type: "uint256" },
    { name: "listingRate", type: "uint256" },
    { name: "startTime", type: "uint256" },
    { name: "endTime", type: "uint256" },
    { name: "lockEndTime", type: "uint256" },
    { name: "isVesting", type: "bool" },
    { name: "isLock", type: "bool" },
    { name: "refund", type: "bool" },
    { name: "autoListing", type: "bool" },
  ],
};

export let currency = "/*ERC20 Token Address is Here*/";
export const presaleRate = "51";
const softcap = ethers.utils.parseEther("3");
export const hardcap = ethers.utils.parseEther("5");
export const minBuy = ethers.utils.parseEther("0.1");
export const maxBuy = ethers.utils.parseEther("0.5");
const liquidityRate = "51";
export const listingRate = "10";
const refund = false;
export const endTime = 1686894294 + 400;
export const startTime = 1686894294 + 100;

export const domain = {
  name: "EIP712Derive",
  version: "1",
  chainId: 31337, //Hardhat mainnet-fork chain id
  verifyingContract: "",
};

export let value = {
  currency,
  presaleRate,
  softcap,
  hardcap,
  minBuy,
  maxBuy,
  liquidityRate,
  listingRate,
  startTime,
  endTime,
  lockEndTime: endTime + 400,
  isVesting: false,
  isLock: true,
  refund,
  autoListing: true
};


export const vesting = {
  tge: 20,
  cliff: 100,
  release: 10,
  startTime: 1000
}

export const changeCurrency = (_currency: string) => {
  value.currency = _currency;
}
