const Ticket = artifacts.require("Ticket");

module.exports = (deployer, network, accounts) => {
  const [dealer, organizer] = accounts;
  deployer.deploy(
    Ticket,
    dealer,
    organizer,
    100,
    false,
    10,
    100,
    "test",
    "tst"
  );
};
