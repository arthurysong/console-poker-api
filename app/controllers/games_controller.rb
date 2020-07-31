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

    def join_game(seat_index = nil)

        game = Game.find(params[:id])
        game.sit(seat_index, @current_user)
            #find first seat available
        @current_user.save

        ActionCable.server.broadcast("game_#{game.id}", { type: "user_join", game: game })
        render json: { success: "#{@current_user.username} has joined game.", user: @current_user }, status: 201
    end

    def leave_game
        game = Game.find(params[:id])

        if @current_user.round && @current_user.round.is_playing
            @current_user.round.player_has_left(@current_user)
        end
        # if @current_user.round #if @current_user is in a round
            # if @current_user.round.is_playing #if @current_user is in a round and is playing..
            #   @current_user.leave_round
            # end
        # end
        game.unsit(@current_user)
        # game.users.delete(@current_user)
        @current_user.game_id = nil

        # i need to make sure they fold the hand they're in...
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
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "All players must be able to afford Big Blind: #{Game.BIG_BLIND}." })
            render json: { error: "All players must be able to afford Big Blind" }
        elsif !game.active_round || !game.active_round.is_playing# if there isn't an active round start the game && !game.active_round.is_playing
            game.start
            game = Game.find(params[:id])

            ActionCable.server.broadcast("game_#{game.id}", { type: "start_game", game: game })

            r = game.active_round # put in move for marley, because Marley only responds to moves that are !blind
            u = r.turn
            if u && u.username == "Marley"
                # binding.pry
                sleep 1.5
                u.call_or_check
            end
            render json: { success: "New Round started" }
        else
            ActionCable.server.broadcast("game_#{game.id}", { type: "errors", error: "Round is still playing." })
            render json: { error: "Round is still playing." }
        end
    end

end
