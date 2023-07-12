const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Contract, Signer } from "ethers";
import IERC20LP from "./abis/ERC20LP.json";
const hre = require("hardhat");

describe("Lock", () => {
  const exampleWalletAddress = "0xE1512FB3D7c9bD07FB27D199cC037de5c5F81A31";
  const transferAmount = ethers.utils.parseEther("1");
  let deployer: Signer;
  let user1: Signer;
  let LockContract: Contract;
  let ERC20Contract: Contract;
  beforeEach(async () => {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [exampleWalletAddress],
    });
    deployer = await ethers.getSigner(exampleWalletAddress);
    const signers = await ethers.getSigners();
    user1 = signers[1];
    ERC20Contract = new ethers.Contract(
      "0x811beEd0119b4AfCE20D2583EB608C6F7AF1954f",
      IERC20LP,
      deployer
    );
    const LockFactory = await ethers.getContractFactory(
      "contracts/lock/Lock.sol:Lock"
    );
    LockContract = await LockFactory.deploy();
    await LockContract.deployed();
  });

  it("Should not allow the same address to add multiple referrals", async () => {
    await user1.sendTransaction({
      value: transferAmount,
      to: deployer.getAddress(),
    });
    const deployerAddress = await deployer.getAddress();
    const endTime = (Date.now() / 1000 + 3000).toFixed(0);
    await ERC20Contract.connect(deployer).approve(
      LockContract.address,
      transferAmount
    );
    await LockContract.connect(deployer).lockTokens(
      "0x811beEd0119b4AfCE20D2583EB608C6F7AF1954f",
      deployerAddress,
      transferAmount,
      endTime,
      true
    );
  });
});
