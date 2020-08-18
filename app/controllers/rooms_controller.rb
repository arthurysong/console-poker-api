require 'pry'

class RoomsController < ApplicationController
    skip_before_action :authenticate_request, only: :index
    
    def index
        rooms = Room.all
        render json: rooms, status: :ok
    end

    def show # THIS ACTION IS FOR WHEN USER JOINS A ROOM AND INITIAL FETCH
        # WILL ALSO ADD USER TO THE ROOM
        
        room = Room.find(params[:id])
        room.users << @current_user
        room.save

        ActionCable.server.broadcast("room_#{room.id}", { type: "user_has_joined" })
        ActionCable.server.broadcast("rooms", { type: "user_has_joined", room_id: room.id }) 

        render json: room, status: :ok
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
