module SendMessage::DelegationSystem {
    use aptos_framework::signer;
    use std::option::{Self, Option};
    
    /// Struct representing a delegation relationship
    struct Delegation has store, key {
        delegate: Option<address>,  // Address of the delegate (None if no delegation)
        voting_power: u64,          // Current voting power of this account
    }
    
    /// Initialize delegation for a user with initial voting power
    public fun initialize_delegation(user: &signer, initial_voting_power: u64) {
        let delegation = Delegation {
            delegate: option::none<address>(),
            voting_power: initial_voting_power,
        };
        move_to(user, delegation);
    }
    
    /// Delegate voting power to another address
    public fun delegate_vote(delegator: &signer, delegate_address: address) acquires Delegation {
        let delegator_addr = signer::address_of(delegator);
        
        // Get delegator's delegation info
        let delegator_delegation = borrow_global_mut<Delegation>(delegator_addr);
        let voting_power_to_delegate = delegator_delegation.voting_power;
        
        // Set the delegate
        delegator_delegation.delegate = option::some(delegate_address);
        delegator_delegation.voting_power = 0; // Delegator loses their voting power
        
        // Add voting power to delegate
        if (exists<Delegation>(delegate_address)) {
            let delegate_delegation = borrow_global_mut<Delegation>(delegate_address);
            delegate_delegation.voting_power = delegate_delegation.voting_power + voting_power_to_delegate;
        };
    }


    /// Revoke delegation and reclaim voting power
    public fun revoke_delegation(delegator: &signer) acquires Delegation {
        let delegator_addr = signer::address_of(delegator);
        let delegator_delegation = borrow_global_mut<Delegation>(delegator_addr);
        
        // Check if there's an active delegation
        if (option::is_some(&delegator_delegation.delegate)) {
            let delegate_address = *option::borrow(&delegator_delegation.delegate);
            
            // Clear the delegation first to avoid borrow conflicts
            delegator_delegation.delegate = option::none<address>();
            delegator_delegation.voting_power = 1; // Restore delegator's power
            
            // Remove voting power from delegate in separate scope
            if (exists<Delegation>(delegate_address)) {
                let delegate_delegation = borrow_global_mut<Delegation>(delegate_address);
                if (delegate_delegation.voting_power > 0) {
                    delegate_delegation.voting_power = delegate_delegation.voting_power - 1;
                };
            };
        };
    }
}