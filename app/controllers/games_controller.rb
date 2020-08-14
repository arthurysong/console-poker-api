class GamesController < ApplicationController
    def join_game
        game = Game.find(params[:id])
        game.sit(params["index"], @current_user)
        @current_user.save

        ActionCable.server.broadcast("game_#{game.id}", { type: "user_join", game: game })
        render json: { success: "#{@current_user.username} has joined game.", game_id: game.id }, status: 201
    end

    def leave_game
        game = Game.find(params[:id])

        @current_user.round.player_has_left(@current_user) if @current_user.round && @current_user.round.is_playing
        game.unsit(@current_user)
        @current_user.game_id = nil
        @current_user.reset_user
        @current_user.save
        
        ActionCable.server.broadcast("game_#{game.id}", { type: "user_leave", game: game })
        render json: { success: "#{@current_user.username} has left the game.", user: @current_user }, status: 201
    end

    def start
        game = Game.find(params[:id])
        if game.users.count <= 1
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "Game must have more than one player." })
            render json: { error: "Game must have more than one player." }
        elsif !game.players_have_enough_money?
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "All players must be able to afford Big Blind: #{Game.big_blind}." })
            render json: { error: "All players must be able to afford Big Blind" }
        elsif !game.active_round || !game.active_round.is_playing
            puts 'did i get here?'
            game.start
            game = Game.find(params[:id]) #For some reason, I need to grab the game again...

            ActionCable.server.broadcast("game_#{game.id}", { type: "start_game", game: game })

            # Put in move for marley, because Marley only responds to moves that are !blind
            u = game.active_round.turn
            if u && u.username == "Marley"
                sleep 1.5
                u.call_or_check
            end

            puts 'i got here??'
            render json: { success: "New Round started" }

        else
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "Round is still playing." })
            render json: { error: "Round is still playing." }
        end
    end

end
