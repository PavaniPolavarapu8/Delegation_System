module SendMessage::DelegationSystem {
    use aptos_framework::signer;
    use std::option::{Self, Option};
    
    
    struct Delegation has store, key {
        delegate: Option<address>,  
        voting_power: u64,          
    }
    
    
    public fun initialize_delegation(user: &signer, initial_voting_power: u64) {
        let delegation = Delegation {
            delegate: option::none<address>(),
            voting_power: initial_voting_power,
        };
        move_to(user, delegation);
    }
    
   
    public fun delegate_vote(delegator: &signer, delegate_address: address) acquires Delegation {
        let delegator_addr = signer::address_of(delegator);
        
        
        let delegator_delegation = borrow_global_mut<Delegation>(delegator_addr);
        let voting_power_to_delegate = delegator_delegation.voting_power;
        
     
        delegator_delegation.delegate = option::some(delegate_address);
        delegator_delegation.voting_power = 0; 
        
      
        if (exists<Delegation>(delegate_address)) {
            let delegate_delegation = borrow_global_mut<Delegation>(delegate_address);
            delegate_delegation.voting_power = delegate_delegation.voting_power + voting_power_to_delegate;
        };
    }


    public fun revoke_delegation(delegator: &signer) acquires Delegation {
        let delegator_addr = signer::address_of(delegator);
        let delegator_delegation = borrow_global_mut<Delegation>(delegator_addr);
        
        
        if (option::is_some(&delegator_delegation.delegate)) {
            let delegate_address = *option::borrow(&delegator_delegation.delegate);
            
            
            delegator_delegation.delegate = option::none<address>();
            delegator_delegation.voting_power = 1; 
            
            
            if (exists<Delegation>(delegate_address)) {
                let delegate_delegation = borrow_global_mut<Delegation>(delegate_address);
                if (delegate_delegation.voting_power > 0) {
                    delegate_delegation.voting_power = delegate_delegation.voting_power - 1;
                };
            };
        };
    }

}
