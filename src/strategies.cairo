#[derive(Serde)]
pub enum LosingStrategy {
    None,
    StealBack,
    Reveal,
    Pyrrhus,
}

#[derive(Serde)]
pub enum ReceivingStrategy {
    None,
    Split,
    Reveal,
}
