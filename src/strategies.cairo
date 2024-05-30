#[derive(Serde, Drop)]
pub enum LosingStrategy {
    None,
    StealBack,
    Reveal,
    Pyrrhus,
}

#[derive(Serde, Drop)]
pub enum ReceivingStrategy {
    None,
    Split,
    Reveal,
}
