import {
  changeCurrency,
  hardcap,
  listingRate,
  presaleRate,
  types,
  value, vesting
} from "./constants";

const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Contract, Signer, Wallet } from "ethers";
import IERC20LP from "./abis/ERC20LP.json";
const hre = require("hardhat");

describe("PoolManager", () => {
  const exampleWalletAddress = "0xE1512FB3D7c9bD07FB27D199cC037de5c5F81A31";
  const transferAmount = ethers.utils.parseEther("100");
  const contributeAmount = ethers.utils.parseEther("0.5");
  const tokenAmount = ethers.utils.parseEther("100000000000000000");
  const data = "Permit(address currency,uint256 presaleRate,uint256 softcap,uint256 hardcap,uint256 minBuy,uint256 maxBuy,uint256 liquidityRate,uint256 listingRate,uint256 startTime,uint256 endTime,uint256 lockEndTime,bool isVesting,bool isLock,bool refund,bool autoListing)";
  const hash = ethers.utils.id(data);
  console.log("Permit Typehash: ", hash);
  let wallet;
  let signers;
  let deployer: Signer;
  let deployers: Signer;
  let user1: Signer;
  let PoolManager: Contract;
  let Pool: Contract;
  let Lock: Contract;
  let MockERC20Contract: Contract;
  let proxy: Contract;
  let snapshot;
  let finalizeSnapshot;
  let totalTokenAmount;
  it("Should properly initialize ",async () => {
    snapshot = await hre.network.provider.send("evm_snapshot");
    signers = await ethers.getSigners();
    const signerAddress = process.env.SIGNER;
    deployers = signers[0];
    user1 = signers[1];
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [exampleWalletAddress],
    });
    deployer = await ethers.getSigner(exampleWalletAddress);
    wallet = new ethers.Wallet(process.env.PRIVATE_KEY);
    const LockFactory = await ethers.getContractFactory(
      "contracts/lock/Lock.sol:Lock"
    );
    Lock = await LockFactory.deploy();
    await Lock.deployed();
    const MockERC20Factory = await ethers.getContractFactory(
        "contracts/mocks/ERC20.sol:MockERC20"
    );
    MockERC20Contract = await MockERC20Factory.deploy();
    await MockERC20Contract.deployed();
    changeCurrency(MockERC20Contract.address);
    const PoolFactory = await ethers.getContractFactory(
      "contracts/pools/Pool.sol:Pool"
    );
    Pool = await PoolFactory.deploy(Lock.address);
    await Pool.deployed();
    const PoolManagerFactory = await ethers.getContractFactory(
      "contracts/pools/PoolManager.sol:PoolManager"
    );
    PoolManager = await PoolManagerFactory.deploy(signerAddress, Pool.address);
    await PoolManager.deployed();
    await MockERC20Contract.connect(deployers).approve(
      PoolManager.address,
      tokenAmount
    );
  });

  it("Should properly create presale", async () => {
    const domain = {
      name: "EIP712-Derive",
      version: "1",
      chainId: 31337, //Hardhat mainnet-fork chain id
      verifyingContract: PoolManager.address,
    };
    const signature = await wallet._signTypedData(domain, types, value);
    await Pool.connect(deployers).initialize(PoolManager.address);
    const usersTokenAmount = hardcap * presaleRate;
    const liquidityTokenAmount = hardcap * listingRate;
    totalTokenAmount = usersTokenAmount + liquidityTokenAmount;
    await expect(
      Pool.connect(deployers).initialize(PoolManager.address)
    ).to.be.revertedWith("Already initialized");
    await PoolManager.connect(deployers).createPresale(value, vesting, signature);
    const proxyAddress = await PoolManager.connect(deployers).presales(0);
    proxy = await ethers.getContractAt(
      "contracts/pools/Pool.sol:Pool",
      proxyAddress
    );
    const poolBalance = await MockERC20Contract.connect(deployers).balanceOf(
      proxyAddress
    );
    expect(poolBalance.toString()).to.equal(totalTokenAmount.toString());
  });

  it("Should not contribute before start time", async () => {
    await expect(
      proxy.connect(user1).contribute({ value: contributeAmount })
    ).to.be.revertedWith("The presale is not active at this time.");
  });

  it("Should properly contribute", async () => {
    const snapshotId = await hre.network.provider.send("evm_snapshot");
    await hre.network.provider.send("evm_increaseTime", [300]);
    await hre.network.provider.send("evm_mine");
    for (let i = 10; i < 20; i++) {
      const tempSigner = signers[i];
      await proxy.connect(tempSigner).contribute({ value: contributeAmount });
    }
  });

  it("Should not contribute after end time", async () => {
    const snapshotId = await hre.network.provider.send("evm_snapshot");
    await hre.network.provider.send("evm_increaseTime", [900]);
    await hre.network.provider.send("evm_mine");
    await expect(
      proxy.connect(user1).contribute({ value: contributeAmount })
    ).to.be.revertedWith("The presale is not active at this time.");
    await hre.network.provider.send("evm_revert", [snapshotId]);
  });

  it("Should properly finalize when hardcap reaches", async () => {
    finalizeSnapshot = await hre.network.provider.send("evm_snapshot");
    await proxy.connect(deployers).finalize();
  });

  it("Should properly claim after presale finalized", async () => {
    for (let i = 10; i < 20; i++) {
      const tempSigner = signers[i];
      await proxy.connect(tempSigner).claim();
      const balance = await MockERC20Contract.connect(tempSigner).balanceOf(tempSigner.getAddress());
      const expectedBalance = contributeAmount.mul(value.presaleRate);
      expect(balance.toString()).to.equal(expectedBalance.toString());
    }
  });

  it("Should properly cancel before finalize", async () => {
    await hre.network.provider.send("evm_revert", [finalizeSnapshot]);
    const deployerBeforeBalance = ethers.BigNumber.from(await MockERC20Contract.connect(deployers).balanceOf(deployers.getAddress()));
    await proxy.connect(deployers).cancel();
    const deployerAfterBalance = await MockERC20Contract.connect(deployers).balanceOf(deployers.getAddress());
    const diff = deployerBeforeBalance.add(totalTokenAmount.toString());
    expect(deployerAfterBalance.toString()).to.equal(diff.toString());
  });

  it("Should properly withdraw after cancellation", async () => {
    for (let i = 10; i < 11; i++) {
      const tempSigner = signers[i];
      const beforeWithdraw = await tempSigner.getBalance();
      const tx = await proxy.connect(tempSigner).withdraw();
      const afterWithdraw = await tempSigner.getBalance();
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed;
      const txDetails = await ethers.provider.getTransaction(tx.hash);
      const gasPrice = txDetails.gasPrice;
      const totalGasCost = gasUsed.mul(gasPrice);
      const diff = beforeWithdraw.add(contributeAmount).sub(totalGasCost);
      expect(afterWithdraw.toString()).to.equal(diff.toString());
    }
    await hre.network.provider.send("evm_revert", [snapshot]);
  });
  });
