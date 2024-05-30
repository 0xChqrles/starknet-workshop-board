#[starknet::contract]
pub mod Board {
    use starknet::ContractAddress;
    use board::contract::interface::Player;

    #[storage]
    struct Storage {
        players: Array<Player>,
        points: LegacyMap<ContractAddress, felt252>,
        // revealed:
    }

    // fn register(ref self: ContractState)
}
