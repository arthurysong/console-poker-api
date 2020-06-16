class GamesController < ApplicationController
    def index
        if params[:room_id]
            room = Room.find(params[:room_id])
            if room.game
                render json: room.game
            else
                render json: { error: "Game has not been started."}
            end
        end
    end

    def create
        if params[:room_id]
            room = Room.find(params[:room_id])
            game = Game.create(room: room)
            game.start
            game.save
            render json: game
        end
    end
end
