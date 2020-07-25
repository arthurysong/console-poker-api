require 'pry'
class User < ApplicationRecord
    has_secure_password
    belongs_to :room, optional: true
    belongs_to :game, optional: true
    belongs_to :round, optional: true

    #round_bet
    #chips
    #playing
    #cards
    #dealer
    #winnings

    def as_json(options = {})
        super(methods: [:connected, :possible_moves, :current_hand])
    end 

    def current_hand
        PokerHand.new(self.cards + self.round.access_community_cards).rank.titleize
    end

    def reset_user
        self.cards = ""
        self.round_bet = 0
        self.dealer = false
        self.winnings = 0
        self.save
    end

    def connected
        self.connect_account_id == nil ? false : true
    end

    def possible_moves
        moves = []
        # puts self.round
        if !self.round || !self.playing
            moves
        elsif self.round && self.round.is_playing
            if self.round.turn != self
                moves
            else
                #what moves do i have?
                moves << "Fold"
                moves << "Raise"
                if self.round_bet == self.round.highest_bet_for_phase
                    moves << "Check"
                elsif self.round_bet < self.round.highest_bet_for_phase
                    moves << "Call"
                end
                moves << "All In"
                moves
            end
        end
    end

    def self.find_or_create_by_email(email, username)
        if user = User.find_by(:email => email)
            return user
        else
            user = User.create(:email => email, :username => username, :password => SecureRandom.hex)
        end
    end

    def is_move_valid?
        self.round && self.round.turn == self
    end

    def make_move(move, amount = 0, blinds = false)
        if is_move_valid?
            self.round.make_player_move(move, amount, blinds)
        end
    end

    def leave_round
        self.round.player_has_left(self.id)
    end
end
