const Ticket = artifacts.require("Ticket");
const chai = require("chai");
chai.should();

contract("Ticket", function (accounts) {
  const [dealer, organizer] = accounts;
  beforeEach(async () => {
    this.ticket = await Ticket.new(
      dealer,
      organizer,
      100,
      false,
      10,
      100,
      "test",
      "tst"
    );
  });
  it("Should initialize Ticket with constructor params", async () => {
    const org = await this.ticket.organizer.call();
    const price = await this.ticket.ticketPrice.call();
    const resell = await this.ticket.canResell.call();
    const resellPercentage = await this.ticket.resellPercentage.call();
    const capacity = await this.ticket.capacity.call();
    const eventName = await this.ticket.name.call();
    const eventSymbol = await this.ticket.symbol.call();
    const soldOut = await this.ticket.soldOut.call();
    org.should.be.eq(organizer);
    price.toString().should.be.eq("100");
    resell.should.be.eq(false);
    resellPercentage.toString().should.be.eq("10");
    capacity.toString().should.be.eq("100");
    eventName.should.be.eq("test");
    eventSymbol.should.be.eq("tst");
    soldOut.should.be.eq(false);
  });
});
