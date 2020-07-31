class Game < ApplicationRecord
    belongs_to :room
    has_many :users
    has_many :rounds

    #game should have seats
    #then when round starts it copies from the seats..
    #seats 

    BIG_BLIND = 400

    def as_json(options = {})
        super(only: [:id, :seats], methods: [:active_round, :seats_as_users, :startable], include: [:users])
        # super(only: [:id])
    end 

    def sit(index, u)
        if !index
            self.seats.each_with_index do |s,i|
                if s == nil
                    index = i
                    break
                end
            end
        end
        if !self.seats[index]
            self.users << u
            self.seats[index] = u.id
            self.save
        end #if index == nil, find first seat avail
    end

    def unsit(u)
        index = nil
        self.seats.each_with_index do |s,i|
            index = i if u.id == s
        end
        self.seats[index] = nil
        self.users.delete(u)
        self.save
    end

    def self.BIG_BLIND
        BIG_BLIND
    end

    # def ordered_users
    #     self.users.sort{|a,b| a.id <=> b.id}
    # end
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

        self.rounds.build(small_blind_index: new_index).tap do |new_round|
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
