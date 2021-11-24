const Market = artifacts.require("Market");
const myAccount = process.env.ADMIN_WALLET_ADDRESS;
module.exports = (deployer, network, accounts) => {
  if (network === "development") {
    deployer.deploy(Market, { from: accounts[0] });
  }
  if (network === "rinkeby") {
    deployer.deploy(Market, { from: myAccount });
  }
};
