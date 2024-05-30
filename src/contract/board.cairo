#[starknet::contract]
pub mod Board {
    use core::array::ArrayTrait;
    use core::num::traits::zero::Zero;
    use board::contract::interface::{IBoard, Behaviour, RevealedBehaviour, BoardState};
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::utils::structs::storage_array::{StorageArray, StorageArrayTrait};

    const STARTING_POINTS: felt252 = 100;

    #[storage]
    struct Storage {
        // players
        all_players: StorageArray<ContractAddress>,
        players_count: felt252,
        players_name_to_addr: LegacyMap<felt252, ContractAddress>,
        players_addr_to_name: LegacyMap<ContractAddress, felt252>,

        // rounds
        next_actions: LegacyMap<ContractAddress, Behaviour>,
        next_actions_count: felt252,
        current_round: felt252,

        // state
        points: LegacyMap<ContractAddress, felt252>,

        stolen_points: felt252,
        exposed_stolen_points: felt252,

        given_points: felt252,
        exposed_given_points: felt252,
    }

    //
    // IBoard
    //

    #[abi(embed_v0)]
    impl BoardImpl of IBoard<ContractState> {
        fn board_state(self: @ContractState) -> BoardState {
            let current_round = self.current_round.read();

            BoardState {
                players: array![],
                round: current_round,
            }
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
            assert(self.players_addr_to_name.read(player_address).is_zero(), 'Player already registered');

            // register player in array
            let mut all_players = self.all_players.read();

            all_players.append(player_address);
            self.all_players.write(all_players);

            // increase players count
            let players_count = self.players_count.read();
            self.players_count.write(players_count + 1);

            // register player in maps
            self.players_name_to_addr.write(name, player_address);
            self.players_addr_to_name.write(player_address, name);

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
            assert(self.players_count.read() == self.next_actions_count.read(), 'Some players are not ready');

            // TODO: implement next round logic
        }
    }

    //
    // Internal
    //

    #[derive(Drop)]
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
