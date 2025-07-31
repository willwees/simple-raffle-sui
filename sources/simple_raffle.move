module simple_raffle::simple_raffle {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::random::{Self, Random};
    use sui::event;

    // === Error Codes ===
    const ERaffleNotOpen: u64 = 0;
    const EInsufficientPayment: u64 = 1;
    const ENotOwner: u64 = 2;
    const EAlreadyJoined: u64 = 3;
    const EInsufficientParticipants: u64 = 4;

    const ENTRY_FEE: u64 = 1_000_000_000; // 1 SUI (1e9 = 1 SUI)
    const MIN_PARTICIPANTS: u64 = 2; // Minimum participants to pick a winner

    /// The raffle object.
    public struct Raffle has key {
        id: UID,
        owner: address,
        entrants: vector<address>,
        is_open: bool,
        pool: Coin<SUI>,
        winner: Option<address>,
    }

    // === Events ===
    public struct RaffleCreated has copy, drop {
        raffle_id: ID,
        owner: address,
    }

    public struct PlayerJoined has copy, drop {
        raffle_id: ID,
        player: address,
        total_entrants: u64,
    }

    public struct WinnerPicked has copy, drop {
        raffle_id: ID,
        winner: address,
        prize_amount: u64,
    }

    // === Functions ===

    /// Create a new raffle.
    public entry fun create_raffle(ctx: &mut TxContext) {
        let pool = coin::zero<SUI>(ctx);
        let raffle = Raffle {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            entrants: vector::empty<address>(),
            is_open: true,
            pool,
            winner: option::none<address>(),
        };

        // Emit event for raffle creation
        event::emit(RaffleCreated {
            raffle_id: object::uid_to_inner(&raffle.id),
            owner: raffle.owner,
        });

        transfer::share_object(raffle);
    }

    /// Join the raffle by paying the entry fee.
    public entry fun join(raffle: &mut Raffle, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(raffle.is_open, ERaffleNotOpen);
        assert!(coin::value(payment) >= ENTRY_FEE, EInsufficientPayment);

        let sender = tx_context::sender(ctx);

        // Check for duplicate entries
        assert!(!vector::contains(&raffle.entrants, &sender), EAlreadyJoined);

        vector::push_back(&mut raffle.entrants, sender);

        let accepted = coin::split(payment, ENTRY_FEE, ctx);
        coin::join(&mut raffle.pool, accepted);

        // Emit event for player joining
        let total_entrants = vector::length(&raffle.entrants);
        event::emit(PlayerJoined {
            raffle_id: object::uid_to_inner(&raffle.id),
            player: sender,
            total_entrants,
        });

        // Remainder will be automatically returned if not used
    }

    /// Pick a winner and transfer the pool.
    public entry fun pick_winner(raffle: &mut Raffle, r: &Random, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(raffle.is_open, ERaffleNotOpen);
        assert!(sender == raffle.owner, ENotOwner);
        let count = vector::length(&raffle.entrants);
        assert!(count >= MIN_PARTICIPANTS, EInsufficientParticipants);

        // TODO: use Chainlink VRF or similar for better randomness
        // Use a simple random selection method
        let mut generator = random::new_generator(r, ctx);
        let index = random::generate_u64_in_range(&mut generator, 0, count - 1);

        let winner = *vector::borrow(&raffle.entrants, index);
        raffle.is_open = false;
        raffle.winner = option::some(winner);

        // Transfer the prize
        let pool_value = coin::value(&raffle.pool);
        let prize = coin::split(&mut raffle.pool, pool_value, ctx);
        transfer::public_transfer(prize, winner);

        // Emit event for winner
        event::emit(WinnerPicked {
            raffle_id: object::uid_to_inner(&raffle.id),
            winner: winner,
            prize_amount: pool_value,
        });
    }

    // === View Functions ===

    // Get the list of entrants
    public fun get_entrants(raffle: &Raffle): &vector<address> {
        &raffle.entrants
    }

    // View the number of entrants
    public fun get_entrant_count(raffle: &Raffle): u64 {
        vector::length(&raffle.entrants)
    }

    // Get the total value in the raffle pool
    public fun get_pool_value(raffle: &Raffle): u64 {
        coin::value(&raffle.pool)
    }

    // Check if the raffle is open
    public fun is_open(raffle: &Raffle): bool {
        raffle.is_open
    }

    // View the owner of the raffle
    public fun get_owner(raffle: &Raffle): address {
        raffle.owner
    }

    // Get the winner of the raffle
    public fun get_winner(raffle: &Raffle): Option<address> {
        raffle.winner
    }

    // Check if the raffle has a winner
    public fun has_winner(raffle: &Raffle): bool {
        option::is_some(&raffle.winner)
    }
}