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
        game.users.delete(@current_user)
        @current_user.reset_user
        @current_user.save
        
        ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
        render json: { success: "#{@current_user.username} has left the game."}, status: 201
    end

    def start
        game = Game.find(params[:id])
        if game.users.count > 1
            if !game.active_round #for when game hasn't been started yet.
                if !game.players_have_enough_money?
                    ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "All players must be able to afford Big Blind: #{Game.BIG_BLIND}." })
                else
                    game.start
                    ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
                end
            else #for when game has one round at least...
                if !game.active_round.is_playing
                    if !game.players_have_enough_money?
                        ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "All players must be able to afford Big Blind: #{Game.BIG_BLIND}." })
                    else
                        game.start

                        ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
                    end
                else
                    ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "Round is still playing." })
                end
            end
        else
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "Game must have more than one player." })
        end

        

        render json: game
    end
end
