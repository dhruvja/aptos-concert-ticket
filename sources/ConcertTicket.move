module ConcertTicket::Tickets {

    use std::signer;
    use std::vector;
    use std::string;
    use aptos_framework::coin;

    const E_NO_VENUE: u64 = 0;
    const E_NO_TICKET: u64 = 0;
    const E_MAX_TICKETS: u64 = 2;
    const E_INVALID_TICKET_CODE: u64 = 3;
    const E_INVALID_TICKET_PRICE: u64 = 4;
    const E_INVALID_TICKET_STATUS: u64 = 4;

    struct Ticket has key, store, drop {
        seat: vector<u8>,
        ticket_code: vector<u8>,
        price: u64
    }

    struct Venue has key {
        available_tickets: vector<Ticket>,
        max_tickets: u64
    }

    struct TicketInfo has drop {
        status: bool,
        ticket_code: vector<u8>,
        price: u64,
        index: u64 
    }

    struct TicketEnvelope has key {
        tickets: vector<Ticket>
    } 


    public fun create_venue(venue_owner: &signer, max_tickets: u64) {
        let available_tickets = vector::empty<Ticket>();
        move_to<Venue>(venue_owner, Venue{available_tickets, max_tickets})
    }

    public fun available_ticket_count(venue_owner_addr: address): u64 acquires Venue {
        let venue = borrow_global<Venue>(venue_owner_addr);
        vector::length<Ticket>(&venue.available_tickets)
    }

    public fun create_ticket(venue_owner: &signer, seat: vector<u8>, ticket_code: vector<u8>, price: u64) acquires Venue {
        let venue_owner_addr = signer::address_of(venue_owner);
        assert!(exists<Venue>(venue_owner_addr), E_NO_VENUE);

        let available_tickets_count = available_ticket_count(venue_owner_addr); 
        let venue = borrow_global_mut<Venue>(venue_owner_addr);
        assert!(available_tickets_count <= venue.max_tickets, E_MAX_TICKETS); 

        vector::push_back(&mut venue.available_tickets, Ticket{seat, ticket_code, price});
    }

    public fun get_ticket_info(venue_owner: address, seat: vector<u8>): TicketInfo acquires Venue {
        assert!(exists<Venue>(venue_owner), E_NO_VENUE);
        let length = available_ticket_count(venue_owner);
        let venue = borrow_global<Venue>(venue_owner);
        let i = 0;
        while (i < length) {
            let ticket = vector::borrow<Ticket>(&venue.available_tickets, i);
            if (ticket.seat == seat) {
                return TicketInfo{status: true, ticket_code: ticket.ticket_code, price: ticket.price, index: i}
            } else {
                i = i + 1;
            }
        };
        TicketInfo{status: false, ticket_code: b"", price: 0, index: 0}
    }

    public fun purchase_ticket(buyer: &signer, venue_owner: address, seat: vector<u8>, ) acquires Venue, TicketEnvelope {
        assert!(exists<Venue>(venue_owner), E_NO_VENUE);

        let buyer_addr = signer::address_of(buyer);
        let ticket_info = get_ticket_info(venue_owner, seat);

        let venue = borrow_global_mut<Venue>(venue_owner);
        // TestCoin::transfer_internal(
        let ticket = vector::remove<Ticket>(&mut venue.available_tickets, ticket_info.index);
        if (!exists<TicketEnvelope>(buyer_addr)) {
            move_to<TicketEnvelope>(buyer, TicketEnvelope{tickets: vector::empty<Ticket>()})
        };
        let ticket_envelope = borrow_global_mut<TicketEnvelope>(buyer_addr);
        vector::push_back<Ticket>(&mut ticket_envelope.tickets, ticket);
    }

    #[test(venue_owner = @0x1)]
    public entry fun sender_can_create_venue(venue_owner: signer) {
        create_venue(&venue_owner, 100);
        let venue_owner_addr = signer::address_of(&venue_owner);
        assert!(exists<Venue>(venue_owner_addr), E_NO_VENUE);
    }

    #[test_only]
    struct FakeMoney has drop { }

    #[test(recipient = @0x1)]
    public entry fun sender_can_create_ticket(recipient: signer) acquires Venue {
        create_venue(&recipient, 100); 
        create_ticket(&recipient, b"A24", b"A24001", 100);
        create_ticket(&recipient, b"A25", b"A25001", 500);
        create_ticket(&recipient, b"A26", b"A26001", 1000);
        let recipient_addr = signer::address_of(&recipient);
        let ticket_count = available_ticket_count(recipient_addr);
        let ticket_info = get_ticket_info(recipient_addr, b"A24");
        assert!(ticket_info.ticket_code == b"A24001", E_INVALID_TICKET_CODE);
        assert!(ticket_info.price == 100, E_INVALID_TICKET_PRICE);
        assert!(ticket_info.status, E_INVALID_TICKET_STATUS);
        assert!(ticket_count == 3, E_NO_TICKET);
        // coin::initialize<FakeMoney>(&recipient, string::utf8(b"Fake money"), string::utf8(b"FM"), 6, true);
    }
}