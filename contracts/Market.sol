// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Ticket.sol";

contract Market is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _eventIds;
    address payable public owner;
    struct EventDetails {
        string name;
        string symbol;
        address ticketAddress;
        address payable organizer;
        bool soldOut;
        uint256 price;
        bool exists;
        bool completed;
    }

    uint256 public listingFee = 0.00024 ether;
    event EventListed(string, uint256);
    event EventTicketPurchased(
        address ticketAddress,
        address purchaserAddress,
        uint256 ticketId
    );
    mapping(uint256 => EventDetails) public eventsList;

    mapping(address => EventDetails[]) public eventToUserMapping;

    modifier onlyOwner() {
        require(msg.sender == owner, "This function is restricted to admins");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function listEvent(
        string memory _eventName,
        string memory _eventSymbol,
        uint256 _eventCapacity,
        bool _canResellTickets,
        uint256 _resellPercentage,
        uint256 _ticketPrice
    ) public payable returns (address ticketAddress) {
        require(
            msg.value >= listingFee,
            "You cannot list an event without paying the listing fee"
        );
        //set up id for new event;
        _eventIds.increment();
        uint256 eventId = _eventIds.current();

        //pay listing fee
        owner.transfer(msg.value);

        //create event contract
        Ticket eventTicket = new Ticket(
            owner,
            msg.sender,
            _ticketPrice,
            _canResellTickets,
            _resellPercentage,
            _eventCapacity,
            _eventName,
            _eventSymbol
        );

        //create eventdetails struct
        EventDetails memory details = EventDetails({
            name: _eventName,
            symbol: _eventSymbol,
            ticketAddress: address(eventTicket),
            organizer: payable(msg.sender),
            soldOut: false,
            price: _ticketPrice,
            exists: true,
            completed: false
        });

        //map eventid to event details struct
        eventsList[eventId] = details;

        //emit event
        emit EventListed(_eventName, eventId);

        //add event details to event array mapped to the current msg.sender
        eventToUserMapping[msg.sender].push(details);
        return address(eventTicket);
    }

    function getUserEvents(address organizer)
        public
        view
        returns (EventDetails[] memory)
    {
        return eventToUserMapping[organizer];
    }

    function purchaseEventTicket(
        uint256 eventId,
        string memory purchaserFullname
    ) public payable {
        bool validEventId = eventsList[eventId].exists;
        if (validEventId == false) {
            revert("Invalid event Id provided");
        }
        address txAddress = eventsList[eventId].ticketAddress;
        uint256 ticketPrice = eventsList[eventId].price;
        require(
            msg.value > ticketPrice,
            "Value provided is less than ticket price"
        );
        eventsList[eventId].organizer.transfer(msg.value);

        Ticket ticket = Ticket(txAddress);
        uint256 id = ticket.createToken(purchaserFullname, msg.sender);
        emit EventTicketPurchased(txAddress, msg.sender, id);
    }
}
