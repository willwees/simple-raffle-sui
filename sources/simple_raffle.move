module simple_raffle::simple_raffle {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::random::{Self, Random};

    // === Error Codes ===
    const ERaffleNotOpen: u64 = 0;
    const EInsufficientPayment: u64 = 1;
    const ENotOwner: u64 = 2;
    const ENoEntrants: u64 = 3;

    const ENTRY_FEE: u64 = 1_000_000_000; // 1 SUI (1e9 = 1 SUI)

    /// The raffle object.
    public struct Raffle has key {
        id: UID,
        owner: address,
        entrants: vector<address>,
        is_open: bool,
        pool: Coin<SUI>,
    }

    /// Create a new raffle.
    public entry fun create_raffle(ctx: &mut TxContext) {
        let pool = coin::zero<SUI>(ctx);
        let raffle = Raffle {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            entrants: vector::empty<address>(),
            is_open: true,
            pool,
        };
        transfer::share_object(raffle);
    }

    /// Join the raffle by paying the entry fee.
    public entry fun join(raffle: &mut Raffle, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(raffle.is_open, ERaffleNotOpen);
        assert!(coin::value(payment) >= ENTRY_FEE, EInsufficientPayment);

        let sender = tx_context::sender(ctx);
        vector::push_back(&mut raffle.entrants, sender);

        let accepted = coin::split(payment, ENTRY_FEE, ctx);
        coin::join(&mut raffle.pool, accepted);
        // Remainder will be automatically returned if not used
    }

    /// Pick a winner and transfer the pool.
    public entry fun pick_winner(raffle: &mut Raffle, r: &Random, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(raffle.is_open, ERaffleNotOpen);
        assert!(sender == raffle.owner, ENotOwner);
        let count = vector::length(&raffle.entrants);
        assert!(count > 0, ENoEntrants);

        // TODO: use Chainlink VRF or similar for better randomness
        // Use a simple random selection method
        let mut generator = random::new_generator(r, ctx);
        let index = random::generate_u64_in_range(&mut generator, 0, count - 1);

        let winner = *vector::borrow(&raffle.entrants, index);
        raffle.is_open = false;

        // Transfer the prize
        let pool_value = coin::value(&raffle.pool);
        let prize = coin::split(&mut raffle.pool, pool_value, ctx);
        transfer::public_transfer(prize, winner);
    }
}