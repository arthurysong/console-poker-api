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
