#[derive(Serde, Drop, starknet::Store)]
pub enum LosingStrategy {
    None,
    StealBack,
    Expose,
    Pyrrhus,
}

#[derive(Serde, Drop, starknet::Store)]
pub enum ReceivingStrategy {
    None,
    Split,
    Expose,
}
