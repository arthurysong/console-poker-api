require 'pry'
# require 'ruby-poker'

class Round < ApplicationRecord
    belongs_to :game
    has_many :users

    #phase
    #small_blind_index
    #turn_index
    #pot
    #highest_bet_for_phase
    #is_playing
    #no_players_for_phase
    #turn_count
    #community_cards
    #all_in
    #status
    #result

    PRE_FLOP = 0
    FLOP = 1
    TURN = 2
    RIVER = 3

    SMALL_BLIND = 200
    BIG_BLIND = 400

    def as_json(options = {})
        super(only: [:id, :pot, :highest_bet_for_phase, :is_playing, :phase, :result], methods: [:access_community_cards, :ordered_users, :turn])
    end 

    def ordered_users
        self.users.sort{|a,b| a.id <=> b.id}
    end

    def turn 
        return active_players[self.turn_index] if self.is_playing
        nil
    end

    def turn= (user)
        self.ordered_users.each_with_index do |u, i|
            if user == u
                self.turn_index = i
                self.save
                break
            end
        end
    end

    def active_players
        self.users.select {|player| player.playing }.sort{|a, b| a.id <=> b.id}
    end

    def access_community_cards
        case self.phase
        when PRE_FLOP
            return ""
        when FLOP
            return self.community_cards[0..7]
        when TURN
            return self.community_cards[0..10]
        else
            return self.community_cards
        end
    end

    def phase_finished?
        players_have_bet? && self.turn_count > self.no_players_for_phase
    end

    def players_have_bet?
        self.active_players.each do |player|
            return false if player.round_bet < self.highest_bet_for_phase
        end
        true
    end

    def start
        # self.status << "ROUND STARTING"
        self.game.users.each {|p| p.set_playing(self.id) }
        self.is_playing = true

        set_dealer
        set_cards
        start_betting_round

        self.save
    end

    def set_dealer
        dealer_index = (self.small_blind_index - 1) % self.users.length
        self.ordered_users[dealer_index].dealer = true
    end

    def player_has_left(user_id) # this will get reworked once i change the arrays around ...
        #need to fix this once I add new seating arrangements..
    end

    def set_cards
        # self.status << "...Dealing cards..."
        deck = []
        ['c', 'd', 'h', 's'].each do |color|
            [2, 3, 4, 5, 6, 7, 8, 9, 'T', 'J', 'Q', 'K', 'A'].each do |number|
                deck << number.to_s + color
            end
        end

        community_cards = []
        5.times { community_cards << deck.delete_at(Random.rand(deck.length)) }
        self.community_cards = community_cards.join(' ')
        self.save

        #deal cards to players
        self.active_players.each do |player|
            player.cards = "#{deck.delete_at(Random.rand(deck.length))} #{deck.delete_at(Random.rand(deck.length))}"
            player.save
        end
    end

    def reset_turn_index
        #this is responsible for finding first person to go in each round.
        i = self.small_blind_index
        while true 
            i = i % self.ordered_users.count
            if self.ordered_users[i].playing
                self.turn = self.ordered_users[i] #turn= will use user to set turn_index
                break
            end
            i += 1
        end
        self.save
    end

    def start_betting_round
        self.active_players.each do |player| 
            player.round_bet = 0
            player.checked = false
            player.save
        end 

        reset_turn_index
        self.no_players_for_phase = active_players.count
        self.highest_bet_for_phase = 0
        self.turn_count = 1

        if self.phase == 0
            self.turn.make_move('raise', SMALL_BLIND, true) # put in blinds for preflop round
            self.turn.make_move('raise', BIG_BLIND, true) # put in blinds for preflop round
        end

        self.save
    end

    def next_turn(blinds = false)
        self.turn_index = (self.turn_index + 1) % (self.active_players.count)

        self.turn_count += 1 unless blinds
    end

    def make_player_move(command, amount = 0, blinds = false)
        #setting the turn info to broadcast to subscribers??
        moved_user = turn
        turn_index = self.turn_index
        case command
        when 'fold'
            folding_player = turn
            folding_player.playing = false
            folding_player.save

            self.turn_index = self.turn_index % self.active_players.count
            
            self.turn_count += 1
            self.save
        when 'check'
            if self.highest_bet_for_phase == 0 || turn.round_bet == self.highest_bet_for_phase
                turn.checked = true
                turn.save
                next_turn
                self.save
            end
        when 'call'
            if self.highest_bet_for_phase > turn.round_bet || self.highest_bet_for_phase == 0
                money_to_leave_player = self.highest_bet_for_phase - turn.round_bet
                turn.round_bet = self.highest_bet_for_phase
                turn.chips -= money_to_leave_player
                self.all_in = true if turn.chips == 0

                self.pot += money_to_leave_player
                turn.save

                next_turn
                self.save
            end
        when 'raise'
            if can_players_afford?(amount) && amount > self.highest_bet_for_phase
                money_to_leave_player = amount - turn.round_bet
                turn.round_bet = amount
                turn.chips -= money_to_leave_player
                turn.save
                self.all_in = true if turn.chips == 0
                self.pot += money_to_leave_player
                self.highest_bet_for_phase = amount
                next_turn(blinds)
                self.save
            end
        when 'allin'
            turn.make_move('raise', max_raise_level)
        end

        ActionCable.server.broadcast("game_#{self.game.id}", { 
                type: "new_move", 
                turn_index: turn_index, 
                command: command, 
                moved_user: moved_user, 
                }) if !blinds 

        if check_if_over
            end_game_by_fold
        elsif phase_finished?
            initiate_next_phase
        end

        ActionCable.server.broadcast("game_#{game.id}", { 
            type: "marleys_turn" }) if turn && turn.username == "Marley"

        ActionCable.server.broadcast("game_#{game.id}", { 
                type: "update_game_after_move", 
                game: game }) if !blinds
    end

    def max_raise_level
        max = 0
        active_players.each_with_index do |player, index|
            player_max = player.chips + player.round_bet
            max = player_max if player_max < max || index == 0
        end
        max
    end

    def can_players_afford?(amount)
        self.active_players.each do |player|
            money_to_leave_player = amount - player.round_bet
            if player.chips < money_to_leave_player
                return false
            end
        end
        true
    end

    def initiate_next_phase
        # or if all in, just go to showdown
        if all_in || self.phase == 3 
            self.phase = 3
            self.save
            showdown
        else
            self.phase += 1
            start_betting_round
        end
    end

    def showdown
        best_hands = []
        best_players = []
        # phase = 3
        active_players.each_with_index do |player, index|
            hand = PokerHand.new(player.cards + " " + self.community_cards)
            if index == 0 || hand == best_hands[0]
                best_hands << hand
                best_players << player
            elsif hand > best_hands[0]
                best_hands = [hand]
                best_players = [player]
            end
        end
        
        split = self.pot / best_players.count
        best_ids = {} # so we can return ids that won in a hash, for client to put sound
        best_players.each do |player|
            best_ids[player.id] = true
            player.chips += split
            player.winnings = split
            player.save
        end

        ActionCable.server.broadcast("game_#{self.game.id}", { 
                type: "game_end_by_showdown",
                winner_ids: best_ids 
            })

        self.is_playing = false
        self.save
    end


    def end_game_by_fold
        last_player = self.active_players[0]
        last_player.chips += self.pot
        last_player.winnings = self.pot
        last_player.save

        self.is_playing = false

        ActionCable.server.broadcast("game_#{self.game.id}", { 
                type: "game_end_by_fold",
                winner_ids: { [last_player.id] => true } 
            }) 
    end

    def check_if_over
        self.active_players.count == 1
    end
end
