#[derive(Serde, Drop, starknet::Store)]
pub enum LosingStrategy {
    None,
    StealBack,
    Reveal,
    Pyrrhus,
}

#[derive(Serde, Drop, starknet::Store)]
pub enum ReceivingStrategy {
    None,
    Split,
    Reveal,
}
