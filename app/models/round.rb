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
        if self.is_playing 
            active_players[self.turn_index]
        else
            nil
        end
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
        if self.phase == PRE_FLOP
            return ""
        elsif self.phase == FLOP
            return self.community_cards[0..7]
        elsif self.phase == TURN
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
            if player.round_bet < self.highest_bet_for_phase
                return false
            end
        end
        true
    end

    def start
        self.status << "ROUND STARTING"
        self.game.users.each do |player| 
            player.playing = true 
            player.dealer = false
            player.round_id = self.id
            player.round_bet = 0
            player.winnings = 0
            player.save
        end

        dealer_index = self.small_blind_index - 1
        dealer_index = dealer_index % self.users.length
        self.ordered_users[dealer_index].dealer = true
        
        self.is_playing = true
        self.save

        set_cards
        start_betting_round
    end

    def player_has_left(user_id)
        user = self.ordered_users.detect {|u| u.id == user_id}
        
        self.status << "#{user.username} has left the game."
        self.save
        if self.turn == user
            self.make_player_move('fold')
        else
            
            user.playing = false
            user.round_bet = 0
            user.cards = ""
            user.save

            self.no_players_for_phase -= 1

            reset_turn_index 
            self.turn_index += self.turn_count - 1
            self.turn_index = self.turn_index % self.active_players.count

            self.save

            if check_if_over #check if game is over or next phase should happen.
                # binding.pry
                end_game_by_fold
            end
        end

        if self.active_players.count == 0
            self.status << "Everyone has left. Game ending."
            self.is_playing = false
            self.save
        end
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
        5.times do 
            c = deck.delete_at(Random.rand(deck.length))
            community_cards << c
        end

        self.community_cards = community_cards.join(' ')
        self.save

        #deal cards to players
        self.active_players.each do |player|
            cards = []
            2.times do 
                c = deck.delete_at(Random.rand(deck.length))
                cards << c
            end
            player.cards = cards.join(' ')
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
        case self.phase
        when PRE_FLOP
            self.status << "\nXXXXXXXXX Pre-flop XXXXXXXXX\n"
        when FLOP
            self.status << "\nXXXXXXXXX Flop XXXXXXXXX\n"
        when TURN
            self.status << "\nXXXXXXXXX Turn XXXXXXXXX\n"
        when RIVER
            self.status << "\nXXXXXXXXX River XXXXXXXXX\n"
        end

        self.active_players.each do |player| 
            player.round_bet = 0
            player.save
        end 

        reset_turn_index
        self.no_players_for_phase = active_players.count
        self.highest_bet_for_phase = 0
        self.turn_count = 1
        self.save

        if self.phase == 0
            self.status << "Collecting Blinds (200, 400)."
            self.turn.make_move('raise', SMALL_BLIND, true) # put in blinds for preflop round
            self.turn.make_move('raise', BIG_BLIND, true) # put in blinds for preflop round
        end
            self.status << "\n#{turn.username}'s turn."
        self.save
    end

    def next_turn(blinds = false)
        if self.turn_index < active_players.count-1
            self.turn_index += 1
        else
            self.turn_index = 0
        end

        unless blinds
            self.status << "\n#{turn.username}'s turn." unless phase_finished?
            self.turn_count += 1 unless blinds
        end
    end

    def make_player_move(command, amount = 0, blinds = false)
        #setting the turn info to broadcast to subscribers??
        moved_user = turn
        turn_index = self.turn_index

        if command == "fold"
            self.status << "#{turn.username} folds."
            folding_player = turn
            folding_player.playing = false
            folding_player.save

            if self.turn_index == self.active_players.count # if last person folds, i need to set index to first person
                self.turn_index = 0
            end
            
            #what if last person is the small_blind_index and they fold?
            # self.small_blind_index = self.small_blind_index % self.active_players.count
            unless check_if_over
                self.status << "#{turn.username}'s turn.\n"
            end
            # self.status << "#{turn.username}'s turn..." unless check_if_over
            self.turn_count += 1
            self.save
        elsif command == "check"
            # add check
            if self.highest_bet_for_phase == 0 || turn.round_bet == self.highest_bet_for_phase
                self.status << "#{turn.username} checks"
                next_turn
            else
                self.status << "Invalid move. Please try again."
            end
            self.save
        elsif command == "call"
            if self.highest_bet_for_phase > turn.round_bet || self.highest_bet_for_phase == 0
                self.status << "#{turn.username} calls."
                money_to_leave_player = self.highest_bet_for_phase - turn.round_bet
                turn.round_bet = self.highest_bet_for_phase
                turn.chips -= money_to_leave_player
                if turn.chips == 0
                    self.all_in = true
                    self.status << "#{turn.username} is all in."
                end

                self.pot += money_to_leave_player
                turn.save

                #increment turn index
                next_turn
            else
                self.status << "Invalid move. Please try again."
            end
            self.save
        elsif command == "raise"
            if can_players_afford?(amount) && amount > self.highest_bet_for_phase
                if blinds 
                    self.status << "#{turn.username}: #{amount}"
                else
                    self.status << "#{turn.username} raises to #{amount}."
                end
              
                turn.username
                money_to_leave_player = amount - turn.round_bet
                turn.round_bet = amount
                turn.chips -= money_to_leave_player
                turn.save

                if turn.chips == 0
                    self.all_in = true 
                    self.status << "#{turn.username} is all in."
                end
                # binding.pry
                self.pot += money_to_leave_player
                self.highest_bet_for_phase = amount
                next_turn(blinds)
            else
                self.status << "Invalid raise amount. Please make sure all players can afford raise amount."
            end
            self.save
        elsif command == "allin"
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
        
        self.status << " "
        if best_players.count == 1
            self.status << "#{best_players[0].username} has the best hand with #{best_hands[0]}"
            self.status << "#{best_players[0].username} wins #{self.pot}!"
            # self.result << "#{best_players[0].username} has the best hand with #{best_hands[0]}"
            # self.result << "#{best_players[0].username} wins #{self.pot}!"
            self.result << "#{best_players[0].username} wins #{self.pot} with #{best_hands[0].rank}"
        else
            string = "Tie!"
            best_players.each_with_index do |player, index|
                string += "\n#{player.username} has #{best_hands[index].rank}"
                
            end
            self.status << string
            self.status << "#{self.pot} is split between the winners."
            self.result << "#{self.pot} is split between the winners."
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
        self.status << "\n#{last_player.username} wins #{self.pot}!"
        self.result << "\n#{last_player.username} wins #{self.pot}!"
        self.save

        ActionCable.server.broadcast("game_#{self.game.id}", { 
                type: "game_end_by_fold",
                winner_ids: { [last_player.id] => true } 
            }) 
    end

    def check_if_over
        self.active_players.count == 1
    end
end
