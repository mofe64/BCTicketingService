const Market = artifacts.require("Market");
const myAccount = process.env.ADMIN_WALLET_ADDRESS;
module.exports = (deployer) => {
  deployer.deploy(Market, { from: myAccount });
};
