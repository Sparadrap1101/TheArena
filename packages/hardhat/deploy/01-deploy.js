const { network, ethers } = require("hardhat");
const { verify } = require("../utils/verify.js");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const vrfCoordinatorAddr = "";
  const keyHash = "";
  const subscriptionId = 0;
  const weaponsScoreUnit = [];

  const args = [vrfCoordinatorAddr, keyHash, subscriptionId, weaponsScoreUnit];

  const theArena = await deploy("TheArena", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: 6,
  });
};

module.exports.tags = ["all", "theArena", "deployments"];
