const { network, ethers } = require("hardhat");
const { verify } = require("../utils/verify.js");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const vrfCoordinatorAddr = "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed";
  const keyHash = "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f";
  const subscriptionId = 6715;
  const weaponsScoreUnit = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32, 33,
  ];

  const args = [vrfCoordinatorAddr, keyHash, subscriptionId, weaponsScoreUnit];

  const theArena = await deploy("TheArena", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: 6,
  });

  const developmentChains = ["hardhat", "localhost"];

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...");
    await verify(theArena.address, args);
  }

  log("--------------------------------");
};

module.exports.tags = ["all", "theArena", "deployments"];
