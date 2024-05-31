use starknet::ContractAddress;

#[starknet::interface]
pub trait BoardABI<TState> {
    fn steal(ref self: TState, name: felt252);
    fn give(ref self: TState, name: felt252);
    fn register(ref self: TState, name: felt252);
    fn next_round(ref self: TState);
}

#[starknet::interface]
pub trait IBoard<TState> {
    fn board_state(self: @TState) -> BoardState;

    fn steal(ref self: TState, name: felt252);
    fn give(ref self: TState, name: felt252);
    fn register(ref self: TState, name: felt252);
    fn next_round(ref self: TState);
}

#[derive(Drop, Serde)]
pub struct BoardState {
    pub players: Array<PlayerState>,
    pub round: felt252,
}

#[derive(Drop, Serde)]
pub struct PlayerState {
    pub name: felt252,
    pub address: ContractAddress,
    pub exposed_stealing: ExposedBehaviour,
    pub exposed_giving: ExposedBehaviour,
    pub points: felt252,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct ExposedBehaviour {
    pub count: felt252,
    pub exposer: ContractAddress,
}

#[derive(Drop, Serde, PartialEq, starknet::Store)]
pub enum Behaviour {
    None,
    Steal: ContractAddress,
    Give: ContractAddress,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct RevealedBehaviour {
    from: felt252,
    behaviour: Behaviour,
    at_round: felt252,
}
