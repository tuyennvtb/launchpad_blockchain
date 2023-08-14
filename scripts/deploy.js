// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  /*
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const lockedAmount = hre.ethers.parseEther("0.001");
  */
  const SBT = await ethers.getContractFactory("Launchpad");

  //const Box = await ethers.getContractFactory('Box');
  
  console.log('Deploying Box...');
  //const box = await upgrades.deployProxy(SBT, [42], { initializer: 'store' });

  
  const SBT_Token = await SBT.deploy();
  //const SBT_Token = await box.deployed();
  
  console.log("Contract deployed to address:", SBT_Token.address)

  console.log(
    `deployed to ${SBT_Token.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
