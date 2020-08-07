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
    #checked

    def as_json(options = {})
        super(methods: [:connected, :possible_moves, :current_hand])
    end 

    def current_hand # Formatting the rank method for PokerHand
        if self.round && self.cards && self.round.access_community_cards != "" 
            rank = PokerHand.new(self.cards + self.round.access_community_cards).rank.titleize
            rank = "High Card" if rank == "Highest Card"
            rank
        end
    end

    def reset_user
        self.cards = ""
        self.round_bet = 0
        self.dealer = false
        self.winnings = 0
        self.checked = false
        self.save
    end

    def call_or_check
        self.round.highest_bet_for_phase > self.round_bet ? self.make_move("call") : self.make_move("check")
    end

    def set_playing(round_id)
        self.playing = true
        self.round_id = round_id
        reset_user
    end

    def connected
        self.connect_account_id == nil ? false : true
    end

    def possible_moves # What moves does a user have, so client can render move buttons
        return nil if !self.round || !self.playing

        moves = []
        if self.round.turn == self
            moves << "Fold"
            moves << "Raise"
            moves << (self.round_bet < self.round.highest_bet_for_phase ? "Call" : "Check") # User's round bet will only be less than or equal to
            moves << "All In"
            moves
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
        self.round.make_player_move(move, amount, blinds) if is_move_valid?
    end

    def leave_round
        self.round.player_has_left(self.id)
    end
end
