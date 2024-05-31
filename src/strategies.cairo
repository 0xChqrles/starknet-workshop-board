#[derive(Serde, Drop, starknet::Store)]
pub enum LosingStrategy {
    None,
    StealBack,
    Expose,
    Fight,
}

#[derive(Serde, Drop, starknet::Store)]
pub enum ReceivingStrategy {
    None,
    Split,
    Expose,
}
