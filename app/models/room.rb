class Room < ApplicationRecord
    has_many :users
    has_one :chatbox
    has_many :messages, through: :chatbox
    has_one :game
    has_secure_password :validations => false

    def as_json(options = {})
        # super(only: [:name, :id, :game_id], methods: [:no_users, :has_password], include: [:users, :game])
        super(only: [:name, :id], methods: [:no_users, :has_password, :big_blind, :game_id])
    end 

    def no_users
        self.users.count
    end

    def big_blind
        self.game.big_blind
    end

    def has_password
        self.password_digest != nil ? true : false
    end
end
