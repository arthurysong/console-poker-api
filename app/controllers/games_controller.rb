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

    def join_game
        game = Game.find(params[:id])
        game.users << @current_user
        @current_user.save

        ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
        render json: { success: "#{@current_user.username} has joined game."}, status: 201
    end

    def leave_game
        game = Game.find(params[:id])

        if @current_user.round #if @current_user is in a round
            if @current_user.round.is_playing #if @current_user is in a round and is playing..
              @current_user.leave_round
            end
        end

        game.users.delete(@current_user)

        # i need to make sure they fold the hand they're in...
        @current_user.reset_user
        @current_user.save
        
        ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
        render json: { success: "#{@current_user.username} has left the game."}, status: 201
    end

    def start
        game = Game.find(params[:id])
        if game.users.count <= 1
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "Game must have more than one player." })
            render json: { error: "Game must have more than one player." }
        elsif !game.players_have_enough_money?
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "All players must be able to afford Big Blind: #{Game.BIG_BLIND}." })
            render json: { error: "All players must be able to afford Big Blind" }
        elsif !game.active_round || !game.active_round.is_playing# if there isn't an active round start the game && !game.active_round.is_playing
            game.start
            game = Game.find(params[:id])

            ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
            render json: { success: "New Round started" }
        else
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "Round is still playing." })
            render json: { error: "Round is still playing." }
        end
    end

end
