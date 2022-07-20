const CrowFunding = artifacts.require("CrowFunding");

module.exports = function (deployer) {
  deployer.deploy(CrowFunding, 10000000000000000000n, 10000);
};
