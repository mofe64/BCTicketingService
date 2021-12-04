// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Ticket.sol";

contract Market {
    using SafeMath for uint256;
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
        uint256 id;
        uint256 date;
    }

    uint256 public listingFee = 0.00024 ether;

    event EventListed(string, uint256);

    event EventTicketPurchased(
        string eventName,
        uint256 eventId,
        address ticketAddress,
        address purchaserAddress,
        uint256 ticketId
    );

    //represents a mapping of events to the eventId
    mapping(uint256 => EventDetails) public eventsList;

    //represents a mapping of events to an organizer
    mapping(address => EventDetails[]) public eventToOrganizerMapping;

    EventDetails[] public allEvents;

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
        uint256 _ticketPrice,
        uint256 _date
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
            completed: false,
            id: eventId,
            date: _date
        });

        //map eventid to event details struct
        eventsList[eventId] = details;

        //emit event
        emit EventListed(_eventName, eventId);

        //add event details to event array mapped to the current msg.sender
        eventToOrganizerMapping[msg.sender].push(details);

        //add event to list of events;
        allEvents.push(details);

        return address(eventTicket);
    }

    function getUsersEvents(address organizer)
        public
        view
        returns (EventDetails[] memory)
    {
        return eventToOrganizerMapping[organizer];
    }

    function getAllEvents() public view returns (EventDetails[] memory) {
        return allEvents;
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
            msg.value >= ticketPrice,
            "Value provided is less than ticket price"
        );
        eventsList[eventId].organizer.transfer(msg.value);

        Ticket ticket = Ticket(txAddress);
        try ticket.createToken(purchaserFullname, msg.sender) returns (
            uint256 id
        ) {
            emit EventTicketPurchased(
                eventsList[eventId].name,
                eventId,
                txAddress,
                msg.sender,
                id
            );
        } catch Error(string memory reason) {
            if (
                keccak256(bytes(reason)) ==
                keccak256(
                    bytes("Tickets for this event are currently sold out")
                )
            ) {
                //update event details to show sold out
                eventsList[eventId].soldOut = true;
            }
            revert(reason);
        }
    }

    // function resellTicket(
    //     uint256 eventId,
    //     uint256 ticketId,
    //     address buyer
    // ) public payable {
    //     //get event
    //     EventDetails memory details = eventsList[eventId];
    //     require(details.exists == true, "Invalid event Id provided");

    //     //initialize ticket contract
    //     Ticket ticketContract = Ticket(details.ticketAddress);

    //     //calculate percentages
    //     uint256 percentageCut = ticketContract.resellPercentage();
    //     uint256 saleValue = msg.value;
    //     uint256 organizerCut = saleValue.div(100).mul(percentageCut);
    //     uint256 houseCut = saleValue.div(100).mul(1);
    //     uint256 sellerCut = saleValue.sub(organizerCut).sub(houseCut);

    //     //transfer value
    //     details.organizer.transfer(organizerCut);
    //     owner.transfer(houseCut);
    //     address payable sellerPayableAddress = payable(msg.sender);
    //     sellerPayableAddress.transfer(sellerCut);

    //     try ticketContract.resellTicket(ticketId, buyer) {
    //         //do some stuff here
    //     } catch Error(string memory reason) {
    //         revert(reason);
    //     }
    // }
}
