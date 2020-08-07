require 'pry'

class RoomsController < ApplicationController
    def index
        rooms = Room.all
        render json: rooms
    end

    def create
        room = Room.create(room_params)
        room.build_game
        room.save

        render json: room
    end

    def authenticate
        room = Room.find(room_params["id"])
        
        if room.authenticate(room_params["password"])
            render json: room
        else
            render json: { error: "Invalid Password" }, status: 401
        end
    end

    private

    def room_params
        params.permit(:name, :password)
    end
end
