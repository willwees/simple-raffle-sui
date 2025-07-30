#[test_only]
module simple_raffle::simple_raffle_tests {
    use simple_raffle::simple_raffle;
    use sui::test_scenario::{Self as test, next_tx, ctx};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui::test_utils::assert_eq;

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
    fun test_join_raffle_success() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player joins raffle
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx(&mut scenario)); // 1 SUI
            
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            
            // Clean up
            coin::destroy_zero(payment);
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_join_raffle_with_extra_payment() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Player joins with more than required payment
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            let mut payment = coin::mint_for_testing<SUI>(2_000_000_000, ctx(&mut scenario)); // 2 SUI
            
            simple_raffle::join(&mut raffle, &mut payment, ctx(&mut scenario));
            
            // Should have 1 SUI remaining
            assert_eq(coin::value(&payment), 1_000_000_000);
            
            // Clean up
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
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
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
        
        // Owner picks winner
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            simple_raffle::pick_winner(&mut raffle, ctx(&mut scenario));
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 2)]
    fun test_pick_winner_not_owner() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
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
        
        // Non-owner tries to pick winner
        next_tx(&mut scenario, PLAYER1);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            simple_raffle::pick_winner(&mut raffle, ctx(&mut scenario)); // Should fail
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 3)]
    fun test_pick_winner_no_entrants() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
        {
            simple_raffle::create_raffle(ctx(&mut scenario));
        };
        
        // Owner tries to pick winner with no participants
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            simple_raffle::pick_winner(&mut raffle, ctx(&mut scenario)); // Should fail
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }

    #[test, expected_failure(abort_code = 0)]
    fun test_join_closed_raffle() {
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
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
        
        // Owner picks winner (closes raffle)
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            simple_raffle::pick_winner(&mut raffle, ctx(&mut scenario));
            test::return_shared(raffle);
        };
        
        // Another player tries to join closed raffle
        next_tx(&mut scenario, PLAYER2);
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
        let mut scenario = test::begin(OWNER);
        
        // Create raffle
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
        
        // Owner picks winner (closes raffle)
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            simple_raffle::pick_winner(&mut raffle, ctx(&mut scenario));
            test::return_shared(raffle);
        };
        
        // Owner tries to pick winner again
        next_tx(&mut scenario, OWNER);
        {
            let mut raffle = test::take_shared<simple_raffle::Raffle>(&scenario);
            simple_raffle::pick_winner(&mut raffle, ctx(&mut scenario)); // Should fail
            test::return_shared(raffle);
        };
        
        test::end(scenario);
    }
}
