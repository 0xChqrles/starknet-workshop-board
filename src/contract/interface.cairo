use starknet::ContractAddress;

#[starknet::interface]
pub trait BoardABI<TState> {
    fn steal(ref self: TState, name: felt252);
    fn give(ref self: TState, name: felt252);
    fn register(ref self: TState, name: felt252);
    fn next_round(ref self: TState);
}

#[derive(starknet::Store)]
pub struct Player {
    name: felt252,
    address: ContractAddress,
}
