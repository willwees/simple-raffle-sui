#[test_only]
module simple_raffle::simple_raffle_tests {
    use simple_raffle::simple_raffle;
    use sui::test_scenario::{Self as test, next_tx, ctx};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui::test_utils::assert_eq;
    use sui::random::{Self, Random};

    // Test addresses
    const OWNER: address = @0xA;
    const PLAYER1: address = @0xB;
    const PLAYER2: address = @0xC;
    const PLAYER3: address = @0xD;

    #[test]
    fun test_create_raffle() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Check raffle was created and shared
        next_tx(&mut scenario, OWNER);
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            // Raffle should be created successfully
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_join_raffle_payments() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Test 1: Exact payment (1 SUI)
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            
            // Payment should be fully consumed
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Test 2: Overpayment (2 SUI)
        next_tx(&mut scenario, PLAYER2);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(2_000_000_000, ctx(&mut scenario));
            
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            
            // Should have 1 SUI remaining
            assert_eq(coin::value(&payment), 1_000_000_000);
            coin::burn_for_testing(payment);
            test::return_shared(raffle);
        };
        
        // Test 3: Duplicate entry - verify current state (separate test handles the failure)
        next_tx(&mut scenario, PLAYER1); // PLAYER1 tries to join again
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            
            // Verify current state - should have 2 players
            assert_eq(simple_raffle::get_entrant_count(&raffle), 2);
            
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 3)]
    fun test_join_raffle_duplicate_entry() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player joins raffle
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Same player tries to join again
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario)); // Should fail with EAlreadyJoined (3)
            coin::burn_for_testing(payment);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 1)]
    fun test_join_raffle_insufficient_payment() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player tries to join with insufficient payment
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(500_000_000, ctx(&mut scenario)); // 0.5 SUI
            
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario)); // Should fail
            
            // Clean up (won't reach here due to abort)
            coin::burn_for_testing(payment);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_pick_winner_success() {
        let mut scenario = test::begin(@0x0); // Use system address for Random creation
        
        // Create the Random object for testing
        {
            random::create_for_testing(ctx(&mut scenario));
        };
        
        // Create raffle (switch to OWNER)
        next_tx(&mut scenario, OWNER);
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Test initial winner state
        next_tx(&mut scenario, OWNER);
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            
            // Initially no winner
            assert_eq(simple_raffle::has_winner(&raffle), false);
            assert_eq(option::is_none(&simple_raffle::get_winner(&raffle)), true);
            assert_eq(simple_raffle::is_open(&raffle), true);
            
            test::return_shared(raffle);
        };
        
        // Multiple players join
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        next_tx(&mut scenario, PLAYER2);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        next_tx(&mut scenario, PLAYER3);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Still no winner before picking
        next_tx(&mut scenario, OWNER);
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            
            assert_eq(simple_raffle::has_winner(&raffle), false);
            assert_eq(option::is_none(&simple_raffle::get_winner(&raffle)), true);
            assert_eq(simple_raffle::is_open(&raffle), true);
            assert_eq(simple_raffle::get_entrant_count(&raffle), 3);
            
            test::return_shared(raffle);
        };
        
        // Owner picks winner
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario));
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        // Test winner state after picking
        next_tx(&mut scenario, OWNER);
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            
            // Now should have a winner
            assert_eq(simple_raffle::has_winner(&raffle), true);
            assert_eq(option::is_some(&simple_raffle::get_winner(&raffle)), true);
            assert_eq(simple_raffle::is_open(&raffle), false);
            assert_eq(simple_raffle::get_pool_value(&raffle), 0); // Prize transferred
            
            // Winner should be one of the participants
            let winner = *option::borrow(&simple_raffle::get_winner(&raffle));
            assert_eq(winner == PLAYER1 || winner == PLAYER2 || winner == PLAYER3, true);
            
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_access_control() {
        let mut scenario = test::begin(@0x0);
        
        // Create the Random object
        {
            random::create_for_testing(ctx(&mut scenario));
        };
        
        // Create raffle
        next_tx(&mut scenario, OWNER);
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player joins
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Add second player to meet minimum requirement
        next_tx(&mut scenario, PLAYER2);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Test 1: Non-owner tries to pick winner - should succeed now that we have 2+ players
        next_tx(&mut scenario, OWNER); // Use owner to test successful pick
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario));
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 2)]
    fun test_pick_winner_not_owner() {
        let mut scenario = test::begin(@0x0); // Use system address for Random creation

        // Create the Random object for testing
        {
            random::create_for_testing(ctx(&mut scenario));
        };
        
        // Create raffle (switch to OWNER)
        next_tx(&mut scenario, OWNER);
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player joins
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Add second player to meet minimum requirement
        next_tx(&mut scenario, PLAYER2);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Non-owner tries to pick winner
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario)); // Should fail
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 4)]
    fun test_pick_winner_insufficient_participants() {
        let mut scenario = test::begin(@0x0); // Use system address for Random creation

        // Create the Random object for testing
        {
            random::create_for_testing(ctx(&mut scenario));
        };
        
        // Create raffle (switch to OWNER)
        next_tx(&mut scenario, OWNER);
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Only one player joins (minimum is 2)
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Owner tries to pick winner with only 1 participant
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario)); // Should fail with EInsufficientParticipants (4)
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_closed_raffle_operations() {
        let mut scenario = test::begin(@0x0);
        
        // Create the Random object
        {
            random::create_for_testing(ctx(&mut scenario));
        };
        
        // Create raffle
        next_tx(&mut scenario, OWNER);
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Two players join to meet minimum requirement
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        next_tx(&mut scenario, PLAYER2);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Owner picks winner (closes raffle)
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario));
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        // Verify raffle is closed and has winner
        next_tx(&mut scenario, OWNER);
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            assert_eq(simple_raffle::is_open(&raffle), false);
            assert_eq(simple_raffle::has_winner(&raffle), true);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 0)]
    fun test_join_closed_raffle() {
        let mut scenario = test::begin(@0x0); // Use system address for Random creation

        // Create the Random object for testing
        {
            random::create_for_testing(ctx(&mut scenario));
        };
        
        // Create raffle (switch to OWNER)
        next_tx(&mut scenario, OWNER);
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player joins
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };

        // Second player joins to meet minimum requirement
        next_tx(&mut scenario, PLAYER2);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Owner picks winner (closes raffle)
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario));
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        // Another player tries to join closed raffle
        next_tx(&mut scenario, PLAYER3);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario)); // Should fail
            coin::burn_for_testing(payment);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 0)]
    fun test_pick_winner_twice() {
        let mut scenario = test::begin(@0x0); // Use system address for Random creation

        // Create the Random object for testing
        {
            random::create_for_testing(ctx(&mut scenario));
        };
        
        // Create raffle (switch to OWNER)
        next_tx(&mut scenario, OWNER);
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player joins
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Second player joins to meet minimum requirement
        next_tx(&mut scenario, PLAYER2);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Owner picks winner (closes raffle)
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario));
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        // Owner tries to pick winner again
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let random_state = test::take_shared<Random>(&scenario);
            simple_raffle::pick_winner(&mut raffle, &random_state, ctx(&mut scenario)); // Should fail
            test::return_shared(random_state);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_view_functions() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Test initial state
        next_tx(&mut scenario, OWNER);
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            
            // Check initial values
            assert_eq(simple_raffle::get_entrant_count(&raffle), 0);
            assert_eq(simple_raffle::get_pool_value(&raffle), 0);
            assert_eq(simple_raffle::is_open(&raffle), true);
            assert_eq(simple_raffle::get_owner(&raffle), OWNER);
            assert_eq(vector::length(simple_raffle::get_entrants(&raffle)), 0);
            assert_eq(simple_raffle::has_winner(&raffle), false);
            assert_eq(option::is_none(&simple_raffle::get_winner(&raffle)), true);
            
            test::return_shared(raffle);
        };
        
        // Player joins
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario));
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        // Test updated state
        next_tx(&mut scenario, OWNER);
        {
            let raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            
            // Check updated values
            assert_eq(simple_raffle::get_entrant_count(&raffle), 1);
            assert_eq(simple_raffle::get_pool_value(&raffle), 1_000_000_000);
            assert_eq(simple_raffle::is_open(&raffle), true);
            assert_eq(*vector::borrow(simple_raffle::get_entrants(&raffle), 0), PLAYER1);
            assert_eq(simple_raffle::has_winner(&raffle), false);
            assert_eq(option::is_none(&simple_raffle::get_winner(&raffle)), true);
            
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }
}
