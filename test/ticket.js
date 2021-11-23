const Ticket = artifacts.require("Ticket");
const truffleAssert = require("truffle-assertions");
const chai = require("chai");
chai.should();

contract("Ticket", function (accounts) {
  const [dealer, organizer, account1, account2] = accounts;
  beforeEach(async () => {
    this.ticket = await Ticket.new(
      dealer,
      organizer,
      100,
      false,
      10,
      2,
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
    capacity.toString().should.be.eq("2");
    eventName.should.be.eq("test");
    eventSymbol.should.be.eq("tst");
    soldOut.should.be.eq(false);
  });

  it("Should create a new token when correct details given ", async () => {
    const attendeeFullName = "mofe";
    const attendee = account1;
    const response = await this.ticket.createToken(attendeeFullName, attendee, {
      from: attendee,
    });
    const events = response["logs"];
    let ticketSaleEvent;
    events.forEach((event) => {
      if (event["event"] === "TicketSale") {
        ticketSaleEvent = event;
      }
    });
    ticketSaleEvent.should.not.be.eq(undefined);
    const eventArgs = ticketSaleEvent["args"];
    const ticketId = eventArgs["0"].toString();
    const assignedOwner = await this.ticket.ownerOf(ticketId);
    assignedOwner.should.be.eq(attendee);
    const dealerApproved = await this.ticket.isApprovedForAll(
      assignedOwner,
      dealer
    );
    dealerApproved.should.be.eq(true);
  });

  it("should revert if ticket sold out ", async () => {
    const attendeeFullName = "mofe";
    const attendee = account1;
    const response = await this.ticket.createToken(attendeeFullName, attendee, {
      from: attendee,
    });
    const response2 = await this.ticket.createToken(
      attendeeFullName,
      attendee,
      {
        from: attendee,
      }
    );
    const events = response2["logs"];
    let soldOutEvent;
    events.forEach((event) => {
      if (event["event"] === "TicketsSoldOut") {
        soldOutEvent = event;
      }
    });
    soldOutEvent.should.not.be.eq(undefined);
    // console.log(soldOutEvent["args"][0].toString());
    await truffleAssert.reverts(
      this.ticket.createToken(attendeeFullName, attendee, {
        from: attendee,
      })
    );
    const eventSoldOut = await this.ticket.soldOut.call();
    eventSoldOut.should.be.eq(true);
  });
});
