#[derive(Serde, Drop, Store)]
pub enum LosingStrategy {
    None,
    StealBack,
    Reveal,
    Pyrrhus,
}

#[derive(Serde, Drop, Store)]
pub enum ReceivingStrategy {
    None,
    Split,
    Reveal,
}
