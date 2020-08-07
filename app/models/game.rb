class Game < ApplicationRecord
    belongs_to :room
    has_many :users
    has_many :rounds

    #seats 
    #big_blind

    BIG_BLIND = 400

    def as_json(options = {})
        super(only: [:id, :seats, :big_blind], methods: [:active_round, :seats_as_users, :startable], include: [:users])
    end 

    def sit(index, u)
        index = self.seats.find_index(nil) if !index
        if !self.seats[index]
            self.users << u
            self.seats[index] = u.id
            self.save
        end #if index == nil, find first seat avail
    end

    def unsit(u)
        index = nil
        index = self.seats.find_index(u.id)
        self.seats[index] = nil if index # if user was found
        self.users.delete(u)
        self.save
    end

    def self.BIG_BLIND
        BIG_BLIND
    end

    def seats_as_users
        self.seats.map{|id| User.find(id) if id}
    end
    
    def active_round
        self.rounds.last
    end

    def start
        new_index = 0
        if self.active_round
            last_blind_index = self.active_round.small_blind_index
            new_index = (last_blind_index + 1) % self.users.count
        end

        self.rounds.build(small_blind_index: new_index, big_blind: self.big_blind).tap do |new_round|
        # self.rounds.build(small_blind_index: 0).tap do |new_round|
            new_round.save
            new_round.start
        end
        self.save
    end

    def startable
        if !self.active_round  || (self.users.count > 1 && !self.active_round.is_playing && self.players_have_enough_money?)
            return true
        end
        false
    end

    def players_have_enough_money?
        self.users.each do |u|
            return false if u.chips < BIG_BLIND
        end
        true
    end
end
