module ConcertTicket::Tickets {

    use std::signer;

    struct Ticket has key {
        seat: vector<u8>,
        ticket_code: vector<u8>
    }

    public fun create_ticket(reciever: &signer, seat: vector<u8>, ticket_code: vector<u8>) {
        move_to<Ticket>(reciever, Ticket{seat, ticket_code})
    }

    #[test(recipient = @0x1)]
    public entry fun sender_can_create_ticket(recipient: signer){
        create_ticket(&recipient, b"A24", b"A24001");
        let recipient_addr = signer::address_of(&recipient);
        assert!(exists<Ticket>(recipient_addr), 1);
    }

}