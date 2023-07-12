import { ethers } from "hardhat";

async function deploy() {
  const signerAddress = process.env.SIGNER;
  const [deployer] = await ethers.getSigners();
  console.log("Deploying Lock contracts with the account:", deployer.address);
  const LockFactory = await ethers.getContractFactory("Lock");
  const LockContract = await LockFactory.deploy();
  const deployedLockContract = await LockContract.deployed();
  console.log(`Lock contract deployed to: ${deployedLockContract.address}`);

  const PoolFactory = await ethers.getContractFactory("Pool");
  const PoolContract = await PoolFactory.deploy(deployedLockContract.address);
  const deployedPoolContract = await PoolContract.deployed();
  console.log(`Pool contract deployed to: ${deployedPoolContract.address}`);

  const PoolManagerFactory = await ethers.getContractFactory("PoolManager");
  const PoolManagerContract = await PoolManagerFactory.deploy(signerAddress, deployedPoolContract.address);
  const deployedPoolManagerContract = await PoolManagerContract.deployed();
  console.log(`Pool manager contract deployed to: ${deployedPoolManagerContract.address}`);
  await PoolContract.connect(deployer).initialize(deployedPoolManagerContract.address);
}

deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
