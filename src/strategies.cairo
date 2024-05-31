#[derive(Serde, Drop, starknet::Store)]
pub enum LosingStrategy {
    None,
    StealBack,
    Fight,
    Expose,
}

#[derive(Serde, Drop, starknet::Store)]
pub enum ReceivingStrategy {
    None,
    Split,
    Expose,
}
