// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Ticket is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address dealer;
    address public organizer;
    uint256 public ticketPrice;
    bool public canResell;
    uint256 public resellPercentage;
    uint256 public capacity;
    uint256 public ticketsSold;
    bool public soldOut;

    struct Guest {
        string fullname;
    }

    enum currency {
        NGN
    }

    mapping(uint256 => Guest) public GuestList;

    modifier notSoldOut() {
        require(
            ticketsSold < capacity,
            "Tickets for this event are currently sold out"
        );
        _;
    }
    modifier guestCanResell() {
        require(canResell == true, "This Ticket cannot be resold");
        _;
    }

    event TicketsSoldOut(uint256 timeStamp);
    event TicketSale(uint256 ticketId, address to);
    event TicketResale(uint256 ticketId, address from, address to);

    constructor(
        address _dealerAddress,
        address _organizer,
        uint256 _ticketPrice,
        bool _canResell,
        uint256 _resellPercentage,
        uint256 _capacity,
        string memory _eventName,
        string memory _eventSymbol
    ) ERC721(_eventName, _eventSymbol) {
        dealer = _dealerAddress;
        organizer = _organizer;
        canResell = _canResell;
        ticketPrice = _ticketPrice;
        capacity = _capacity;
        resellPercentage = _resellPercentage;
        soldOut = false;
        ticketsSold = 0;
    }

    function createToken(
        string memory attendeeFullName,
        address attendeeAddress
    ) public notSoldOut returns (uint256) {
        _tokenIds.increment();
        uint256 ticketId = _tokenIds.current();
        _safeMint(attendeeAddress, ticketId);
        setApprovalForAll(dealer, true);
        Guest memory newGuest = Guest(attendeeFullName);
        GuestList[ticketId] = newGuest;
        ticketsSold = ticketsSold + 1;
        emit TicketSale(ticketId, attendeeAddress);
        if (ticketsSold == capacity) {
            soldOut = true;
            emit TicketsSoldOut(block.timestamp);
        }
        return ticketId;
    }

    function resellTicket(uint256 ticketId, address buyer)
        public
        guestCanResell
    {
        bool ticketExists = _exists(ticketId);
        require(ticketExists == true, "Ticket id provided does not exist");
        safeTransferFrom(msg.sender, buyer, ticketId);
        emit TicketResale(ticketId, msg.sender, buyer);
    }
}
