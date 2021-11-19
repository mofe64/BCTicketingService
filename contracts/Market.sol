// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    }
    uint256 public listingFee = 0.00024 ether;

    mapping(uint256 => EventDetails) public eventsList;

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
        address _organizerAddress,
        bool _canResellTickets,
        uint256 _resellPercentage,
        uint256 _ticketPrice
    ) public payable onlyOwner returns (address ticketAddress) {
        require(
            msg.value >= listingFee,
            "You cannot list an event without paying the listing fee"
        );
        _eventIds.increment();
        uint256 eventId = _eventIds.current();
        owner.transfer(msg.value);
        Ticket eventTicket = new Ticket(
            owner,
            _organizerAddress,
            _ticketPrice,
            _canResellTickets,
            _resellPercentage,
            _eventCapacity,
            _eventName,
            _eventSymbol
        );
        EventDetails memory details = EventDetails({
            name: _eventName,
            symbol: _eventSymbol,
            ticketAddress: address(eventTicket),
            organizer: payable(_organizerAddress),
            soldOut: false,
            price: _ticketPrice,
            exists: true
        });
        eventsList[eventId] = details;
        return address(eventTicket);
    }

    function purchaseEventTicket(
        uint256 eventId,
        address purchaser,
        string memory purchaserFullname
    ) public payable returns (uint256 ticketId) {
        bool validEventId = eventsList[eventId].exists;
        if (validEventId == false) {
            revert("Invalid event Id provided");
        }

        address txToken = eventsList[eventId].ticketAddress;
        (bool success, bytes memory returnData) = txToken.call(
            abi.encodePacked(
                Ticket(txToken).createToken.selector,
                abi.encode(purchaserFullname, purchaser)
            )
        );

        if (success) {
            uint256 id = abi.decode(returnData, (uint256));
            return id;
        } else {
            return 200;
        }
    }
}
