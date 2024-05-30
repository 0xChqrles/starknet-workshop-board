#[starknet::interface]
pub trait BoardABI<TState> {
    fn steal(ref self: TState, name: felt252);
    fn give(ref self: TState, name: felt252);
}
