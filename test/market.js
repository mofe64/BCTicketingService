const Market = artifacts.require("Market");
const Ticket = artifacts.require("Ticket");
const truffleAssert = require("truffle-assertions");
const chai = require("chai");
chai.should();

//event details constants
const eventName = "marketTest";
const eventSymbol = "MT";
const capacity = 2;
const canResell = false;
const resellPercentage = 0;
const price = 10;

contract("Market", function (accounts) {
  const [organizerAccount, dealer, attendee1, attendee2] = accounts;
  beforeEach(async () => {
    this.market = await Market.new({ from: dealer });
  });

  it("should set the msg.sender to the market owner", async () => {
    const owner = await this.market.owner.call();
    owner.should.be.eq(dealer);
  });

  it("should successfully list an event when correct params are given", async () => {
    //get account balance of dealer before listing
    let dealerAccountBalanceBeforeListing = await web3.eth.getBalance(dealer);
    dealerAccountBalanceBeforeListing = web3.utils.fromWei(
      dealerAccountBalanceBeforeListing.toString(),
      "ether"
    );
    dealerAccountBalanceBeforeListing = parseFloat(
      dealerAccountBalanceBeforeListing
    );

    //attempt to list event
    const response = await this.market.listEvent.sendTransaction(
      eventName,
      eventSymbol,
      capacity,
      canResell,
      resellPercentage,
      price,
      {
        from: organizerAccount,
        value: web3.utils.toWei("10", "ether"),
      }
    );

    //get account balance of dealer after listing
    let dealerAccountBalanceAfterListing = await web3.eth.getBalance(dealer);
    dealerAccountBalanceAfterListing = web3.utils.fromWei(
      dealerAccountBalanceAfterListing.toString(),
      "ether"
    );
    dealerAccountBalanceAfterListing = parseFloat(
      dealerAccountBalanceAfterListing
    );

    dealerAccountBalanceAfterListing.should.be.greaterThan(
      dealerAccountBalanceBeforeListing
    );

    //get listedEventId fom logs
    const events = response["logs"];
    let listingEvent;
    events.forEach((event) => {
      if (event["event"] === "EventListed") {
        listingEvent = event;
      }
    });
    listingEvent.should.not.be.eq(undefined);
    const eventArgs = listingEvent["args"];
    const eventId = eventArgs["1"].toString();
    const eventDetails = await this.market.eventsList.call(eventId);
    const eventTicketAddress = eventDetails["ticketAddress"];
    const ticketInstance = await Ticket.at(eventTicketAddress);
    const ticketEventName = await ticketInstance.name.call();
    const ticketEventSymbol = await ticketInstance.symbol.call();
    const ticketEventCapacity = await ticketInstance.capacity.call();
    ticketEventName.should.be.eq(eventName);
    ticketEventSymbol.should.be.eq(eventSymbol);
    ticketEventCapacity.toString().should.be.eq(capacity.toString());

    // const x = await this.market.getUserEvents.call(organizerAccount);
    // console.log(x);
  });
  it("Should successfully purchase an event ticket", async () => {
    //create event
    const response = await this.market.listEvent.sendTransaction(
      eventName,
      eventSymbol,
      1,
      canResell,
      resellPercentage,
      price,
      {
        from: organizerAccount,
        value: web3.utils.toWei("10", "ether"),
      }
    );

    //get eventId from logs
    const events = response["logs"];
    let listingEvent;
    events.forEach((event) => {
      if (event["event"] === "EventListed") {
        listingEvent = event;
      }
    });
    listingEvent.should.not.be.eq(undefined);
    const eventArgs = listingEvent["args"];
    const eventId = eventArgs["1"].toString();

    //get account balances of the attendee and event organizer before tx
    let organizerBeforeTx = await web3.eth.getBalance(organizerAccount);
    organizerBeforeTx = web3.utils.fromWei(
      organizerBeforeTx.toString(),
      "ether"
    );
    organizerBeforeTx = parseFloat(organizerBeforeTx);
    let attendeeBeforeTx = await web3.eth.getBalance(attendee1);
    attendeeBeforeTx = web3.utils.fromWei(attendeeBeforeTx.toString(), "ether");
    attendeeBeforeTx = parseFloat(attendeeBeforeTx);

    //attempt to buy ticket
    const ticketPurchaseResponse =
      await this.market.purchaseEventTicket.sendTransaction(eventId, "mofe", {
        from: attendee1,
        value: web3.utils.toWei("10", "ether"),
      });

    //get account balances of the attendee and event organizer after tx
    let organizerAfterTx = await web3.eth.getBalance(organizerAccount);
    organizerAfterTx = web3.utils.fromWei(organizerAfterTx.toString(), "ether");
    organizerAfterTx = parseFloat(organizerAfterTx);
    let attendeeAfterTx = await web3.eth.getBalance(attendee1);
    attendeeAfterTx = web3.utils.fromWei(attendeeAfterTx.toString(), "ether");
    attendeeAfterTx = parseFloat(attendeeAfterTx);

    organizerAfterTx.should.be.greaterThan(organizerBeforeTx);
    attendeeAfterTx.should.be.lessThan(attendeeBeforeTx);
    const purchaseEvents = ticketPurchaseResponse["logs"];
    // console.log(purchaseEvents);
    let purchaseEvent;
    purchaseEvents.forEach((event) => {
      if (event["event"] == "EventTicketPurchased") {
        purchaseEvent = event;
      }
    });
    purchaseEvent.should.not.be.eq(undefined);
    const purchaseEventArgs = purchaseEvent["args"];
    const ticketAddress = purchaseEventArgs["ticketAddress"];
    const ticketId = purchaseEventArgs["ticketId"].toString();
    const ticketContractInstance = await Ticket.at(ticketAddress);
    const assignedTicketOwner = await ticketContractInstance.ownerOf(ticketId);
    assignedTicketOwner.should.be.eq(attendee1);
  });
  it("should revert if tickets have been sold out", async () => {
    //list event
    const response = await this.market.listEvent.sendTransaction(
      eventName,
      eventSymbol,
      0,
      canResell,
      resellPercentage,
      price,
      {
        from: organizerAccount,
        value: web3.utils.toWei("10", "ether"),
      }
    );

    //get eventId from logs
    const events = response["logs"];
    let listingEvent;
    events.forEach((event) => {
      if (event["event"] === "EventListed") {
        listingEvent = event;
      }
    });
    listingEvent.should.not.be.eq(undefined);
    const eventArgs = listingEvent["args"];
    const eventId = eventArgs["1"].toString();

    await truffleAssert.reverts(
      this.market.purchaseEventTicket.sendTransaction(eventId, "mofe", {
        from: attendee1,
        value: web3.utils.toWei("10", "ether"),
      })
    );
  });
});
