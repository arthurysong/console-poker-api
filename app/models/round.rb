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
    #seats
    #status (removed)
    #result
    #big_blind

    PRE_FLOP = 0
    FLOP = 1
    TURN = 2
    RIVER = 3

    def as_json(options = {})
        super(only: [:id, :pot, :highest_bet_for_phase, :is_playing, :phase, :result, :big_blind], methods: [:access_community_cards, :turn])
    end 

    def turn 
        self.is_playing ? User.find(self.seats[self.turn_index]) : nil
    end

    def turn= (user)
        self.turn_index = self.seats.find_index(user.id)
        self.save
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

    def active_player_ids
        self.seats.select{|i| i != nil && User.find(i).playing }
    end

    def phase_finished?
        players_have_bet? && self.turn_count > self.no_players_for_phase
    end

    def players_have_bet? #fix
        self.active_player_ids.each do |id|
            player = User.find(id)
            return false if player.round_bet < self.highest_bet_for_phase
        end
        true
    end

    def start
        # self.status << "ROUND STARTING"
        self.game.users.each {|p| p.set_playing(self.id) }
        self.seats = self.game.seats
        self.is_playing = true

        set_dealer
        set_cards
        start_betting_round

        self.save
    end

    def set_dealer
        while self.seats[dealer_index] == nil || dealer_index != self.small_blind_index
            dealer_index = (dealer_index - 1) % 8
        end

        u = User.find(self.seats[dealer_index])
        u.dealer = true
        u.save
    end

    def player_has_left(user) # this will get reworked once i change the arrays around ...
        next_turn if turn == user

        self.seats[self.seats.find_index(user.id)] = nil
        self.users.delete(user)
        self.save

        end_game_by_fold if check_if_over
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

        self.active_player_ids.each do |id|
            player = User.find(id)
            player.cards = "#{deck.delete_at(Random.rand(deck.length))} #{deck.delete_at(Random.rand(deck.length))}"
            player.save
        end
    end

    def reset_turn_index # Responsible for finding first person to go in each round.
        i = self.small_blind_index
        while true 
            if self.seats[i] && User.find(self.seats[i]).playing
                self.turn = User.find(self.seats[i])
                break
            end
            i = (i + 1) % 8
        end
        self.save
    end

    

    def start_betting_round
        self.seats.each do |p| #Reset each player's round_bet and checked
            next if p == nil
            player = User.find(p)
            player.round_bet = 0
            player.checked = false
            player.save
        end

        reset_turn_index
        self.no_players_for_phase = active_player_ids.count
        self.highest_bet_for_phase = 0
        self.turn_count = 1
        self.save # need this to because in next block, for some reason I need to query DB for refreshed round

        if self.phase == 0 # Put in blinds
            self.turn.make_move('raise', self.big_blind/2, true) 
            r = Round.find(self.id) # i'm not sure why the self won't persit i have to grab again.

            r.turn.make_move('raise', self.big_blind, true) 
        end

        self.save
    end

    def next_turn(blinds = false)
        self.turn_index = (self.turn_index + 1) % 8
        while self.seats[self.turn_index] == nil || !User.find(self.seats[self.turn_index]).playing
            self.turn_index = (self.turn_index + 1) % 8
        end

        self.turn_count += 1 unless blinds
    end

    def make_player_move(command, amount = 0, blinds = false)
        # These variables I need when I broadcast to ActionCable
        u = turn 
        turn_index = self.turn_index
        
        case command
        when 'fold'
            u.playing = false
            u.save

            next_turn
            self.save
        when 'check'
            if self.highest_bet_for_phase == 0 || turn.round_bet == self.highest_bet_for_phase
                u.checked = true
                u.save
                next_turn
                self.save
            end
        when 'call'
            if self.highest_bet_for_phase > turn.round_bet || self.highest_bet_for_phase == 0
                money_to_leave_player = self.highest_bet_for_phase - u.round_bet
                u.round_bet = self.highest_bet_for_phase
                u.chips -= money_to_leave_player
                self.all_in = true if u.chips == 0

                self.pot += money_to_leave_player
                u.save

                next_turn
                self.save
            end
        when 'raise'
            if can_players_afford?(amount) && amount > self.highest_bet_for_phase
                money_to_leave_player = amount - u.round_bet
                u.round_bet = amount
                u.chips -= money_to_leave_player
                u.save
                self.all_in = true if u.chips == 0
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
                moved_user: u, 
                }) if !blinds 

        if check_if_over
            end_game_by_fold
        elsif phase_finished?
            initiate_next_phase
        end

        ActionCable.server.broadcast("game_#{game.id}", { 
                type: "update_game_after_move", 
                game: game }) if !blinds
        
        u = turn
        if u && u.username == "Marley" && !blinds
            sleep 1.5
            u.call_or_check
        end
    end

    def max_raise_level # these two should be computated in the beginning of the phase?
        max = 0
        active_player_ids.each_with_index do |id, index|
            player = User.find(id)
            player_max = player.chips + player.round_bet
            max = player_max if player_max < max || index == 0
        end
        max
    end

    def can_players_afford?(amount) # this should be in the beginning of the phase?
        self.active_player_ids.each do |id|
            player = User.find(id)
            return false if player.chips < amount - player.round_bet
        end
    end

    def initiate_next_phase
        if all_in || self.phase == RIVER #If someone is all in or phase RIVER go to showdown
            self.phase = RIVER
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

        active_player_ids.each_with_index do |id, index|
            player = User.find(id)
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
        last_player = User.find(self.active_player_ids[0])
        last_player.chips += self.pot
        last_player.winnings = self.pot
        last_player.save

        self.is_playing = false
        self.save

        ActionCable.server.broadcast("game_#{self.game.id}", { 
                type: "game_end_by_fold",
                winner_ids: { [last_player.id] => true } 
            }) 
    end

    def check_if_over
        self.active_player_ids.count == 1
    end
end
