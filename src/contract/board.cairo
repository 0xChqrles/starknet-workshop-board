#[starknet::contract]
pub mod Board {
    use core::array::ArrayTrait;
    use core::num::traits::zero::Zero;
    use board::contract::interface::{
        IBoard, Behaviour, RevealedBehaviour, BoardState, PlayerState, ExposedBehaviour
    };
    use starknet::{ContractAddress, get_caller_address};
    use board::player::interface::{
        IReacterDispatcher, IReacterDispatcherTrait, LosingStrategy, ReceivingStrategy
    };

    const STARTING_POINTS: felt252 = 100;
    const ROUND_REWARD: felt252 = 10;

    const STEALING_POINTS: felt252 = 5;
    const STEALING_POINTS_STEAL_BACK: (felt252, felt252) = (3, 3);
    const STEALING_POINTS_FIGHT: (felt252, felt252) = (10, 8);

    const GIVING_POINTS: felt252 = 5;
    const GIVING_POINTS_SPLIT: (felt252, felt252) = (3, 3);

    #[storage]
    struct Storage {
        // players
        players_count: felt252,
        players_name_to_addr: LegacyMap<felt252, ContractAddress>,
        players_addr_to_name: LegacyMap<ContractAddress, felt252>,
        players_index_to_addr: LegacyMap<felt252, ContractAddress>,
        // rounds
        next_actions: LegacyMap<ContractAddress, Behaviour>,
        next_actions_count: felt252,
        current_round: felt252,
        // state
        points: LegacyMap<ContractAddress, felt252>,
        stealing_count: LegacyMap<ContractAddress, felt252>,
        exposed_stealing: LegacyMap<ContractAddress, ExposedBehaviour>,
        giving_count: LegacyMap<ContractAddress, felt252>,
        exposed_giving: LegacyMap<ContractAddress, ExposedBehaviour>,
    }

    //
    // IBoard
    //

    #[abi(embed_v0)]
    impl BoardImpl of IBoard<ContractState> {
        fn board_state(self: @ContractState) -> BoardState {
            let current_round = self.current_round.read();

            // get each player infos
            let mut index = 0;
            let players_count = self.players_count.read();
            let mut players_states: Array<PlayerState> = array![];

            loop {
                if index == players_count {
                    break;
                }

                let player_address = self.players_index_to_addr.read(index);
                let name = self.players_addr_to_name.read(player_address);
                let points = self.points.read(player_address);
                let exposed_stealing = self.exposed_stealing.read(player_address);
                let exposed_giving = self.exposed_giving.read(player_address);

                players_states
                    .append(PlayerState { name, address: player_address, points, exposed_stealing, exposed_giving, });

                index += 1;
            };

            // return board state
            BoardState { players: players_states, round: current_round, }
        }

        fn register(ref self: ContractState, name: felt252) {
            // assert game is not already started
            let current_round = self.current_round.read();
            assert(current_round.is_zero(), 'Game already started');

            // assert name is not empty
            assert(name.is_non_zero(), 'Name cannot be empty');

            // get player addr
            let player_address = get_caller_address();

            // assert name is not already registered
            assert(self.players_name_to_addr.read(name).is_zero(), 'Name already registered');

            // assert player is not already registered
            assert(
                self.players_addr_to_name.read(player_address).is_zero(),
                'Player already registered'
            );

            // increase players count
            let players_count = self.players_count.read();
            self.players_count.write(players_count + 1);

            // register player in maps
            self.players_name_to_addr.write(name, player_address);
            self.players_addr_to_name.write(player_address, name);
            self.players_index_to_addr.write(players_count, player_address);

            // distribute starting points
            self.points.write(player_address, STARTING_POINTS);
        }

        fn steal(ref self: ContractState, name: felt252) {
            self._behave(:name, behaviour_type: BehaviourType::Steal);
        }

        fn give(ref self: ContractState, name: felt252) {
            self._behave(:name, behaviour_type: BehaviourType::Give);
        }

        fn next_round(ref self: ContractState) {
            // assert everybody's ready
            assert(
                self.players_count.read() == self.next_actions_count.read(),
                'Some players are not ready'
            );

            // loop through players actions and execute them
            let mut index = 0;
            let players_count = self.players_count.read();

            loop {
                if index == players_count {
                    break;
                }

                let player_address = self.players_index_to_addr.read(index);
                let action = self.next_actions.read(player_address);
                let mut player_points = self.points.read(player_address) + ROUND_REWARD;

                match action {
                    Behaviour::None => panic!("Some players are not ready"),
                    Behaviour::Steal(recipient_address) => {
                        // increase stealing count
                        let stealing_count = self.stealing_count.read(player_address);
                        self.stealing_count.write(player_address, stealing_count + 1);

                        // get recipient losing strategy
                        let recipient = IReacterDispatcher { contract_address: recipient_address };
                        let recipient_strategy = recipient.lose();

                        // get recipient points
                        let mut recipient_points = self.points.read(recipient_address);

                        // applying recipient losing strategy
                        match recipient_strategy {
                            LosingStrategy::None => {
                                // no strategy
                                player_points += STEALING_POINTS;
                                recipient_points -= STEALING_POINTS;
                            },
                            LosingStrategy::Expose => {
                                // exposing strategy
                                player_points += STEALING_POINTS;
                                recipient_points -= STEALING_POINTS;

                                // expose
                                self
                                    .exposed_stealing
                                    .write(
                                        player_address,
                                        ExposedBehaviour {
                                            count: stealing_count + 1, exposer: recipient_address,
                                        }
                                    );
                            },
                            LosingStrategy::StealBack => {
                                // steal back strategy
                                let (losed_by_thief, losed_by_victim) = STEALING_POINTS_STEAL_BACK;

                                player_points -= losed_by_thief;
                                recipient_points -= losed_by_victim;
                            },
                            LosingStrategy::Fight => {
                                // steal back strategy
                                let (losed_by_thief, losed_by_victim) = STEALING_POINTS_FIGHT;

                                player_points -= losed_by_thief;
                                recipient_points -= losed_by_victim;
                            },
                        };

                        // update recipient points
                        self.points.write(recipient_address, recipient_points);
                    },
                    Behaviour::Give(recipient_address) => {
                        // increase giving count
                        let giving_count = self.giving_count.read(player_address);
                        self.giving_count.write(player_address, giving_count + 1);

                        // get recipient receiving strategy
                        let recipient = IReacterDispatcher { contract_address: recipient_address };
                        let recipient_strategy = recipient.receive();

                        // get recipient points
                        let mut recipient_points = self.points.read(recipient_address);

                        // applying recipient receiving strategy
                        match recipient_strategy {
                            ReceivingStrategy::None => {
                                // no strategy
                                recipient_points += GIVING_POINTS;
                            },
                            ReceivingStrategy::Expose => {
                                // exposing strategy
                                recipient_points += GIVING_POINTS;

                                // expose
                                self
                                    .exposed_giving
                                    .write(
                                        player_address,
                                        ExposedBehaviour {
                                            count: giving_count + 1, exposer: recipient_address,
                                        }
                                    );
                            },
                            ReceivingStrategy::Split => {
                                // split back with the donor
                                let (earned_by_donor, earned_by_recipient) = GIVING_POINTS_SPLIT;

                                player_points += earned_by_donor;
                                recipient_points += earned_by_recipient;
                            }
                        };

                        // update recipient points
                        self.points.write(recipient_address, recipient_points);
                    },
                };

                // update player points
                self.points.write(player_address, player_points);

                // remove action
                self.next_actions.write(player_address, Behaviour::None);

                index += 1;
            };

            // reset actions count
            self.next_actions_count.write(0);

            // increase round
            let current_round = self.current_round.read();
            self.current_round.write(current_round + 1);
        }
    }

    //
    // Internal
    //

    #[derive(Drop, Serde)]
    pub enum BehaviourType {
        Steal,
        Give,
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _behave(ref self: ContractState, name: felt252, behaviour_type: BehaviourType) {
            // get player addr
            let from = get_caller_address();

            // assert an action is not already pending for this round
            assert(self.next_actions.read(from) == Behaviour::None, 'Action already registered');

            // get recipient addr
            let to = self.players_name_to_addr.read(name);

            // assert player exist
            assert(to.is_non_zero(), 'Player does not exist');

            // get behaviour
            let behaviour = match behaviour_type {
                BehaviourType::Steal => Behaviour::Steal(to),
                BehaviourType::Give => Behaviour::Give(to),
            };

            // save action
            self.next_actions.write(from, behaviour);

            // increase next actions count
            let next_actions_count = self.next_actions_count.read();
            self.next_actions_count.write(next_actions_count + 1);
        }
    }
}
