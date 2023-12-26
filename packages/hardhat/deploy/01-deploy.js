const { network, ethers } = require("hardhat");
const { verify } = require("../utils/verify.js");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const vrfCoordinatorAddr = "";
  const keyHash = "";
  const subscriptionId = 0;
  const weaponsScoreUnit = [];
};

module.exports.tags = ["all", "theArena", "deployments"];
