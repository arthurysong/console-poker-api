require 'pry'

class UsersController < ApplicationController
    skip_before_action :authenticate_request, only: :create

    def index
        users = User.all
        render json: users
    end

    def create
        user = User.new(user_params)
        
        if user.save
            render json: { user: user }, status: 201
        else 
            render json: { errors: user.errors.full_messages }, status: 400
        end
    end

    def reset_user
        @current_user.reset_user
        render json: { success: "#{@current_user.username} has returned their cards, and reset info.", user: @current_user }, status: 201
    end

    def make_move
        game = @current_user.game

        if @current_user.round
            #make sure move is valid??

            turn_index = @current_user.round.turn_index
            @current_user.make_move(params["command"], params["amount"])

            #need to refresh the user since it's still pointing to old user...
            user = User.find(current_user.id)
            
            # binding.pry
            # ActionCable.server.broadcast("game_#{game.id}", 
            #     { 
            #     type: "new_move", 
            #     turn_index: turn_index, 
            #     command: params["command"], 
            #     moved_user: user, 
            #     game: game 
            # })

            render json: { message: "Move Success." }
        else
            render json: { error: "User is not in current round."}
        end
    end

    def marley_call
        user = User.find_by(username: "Marley")
        turn_index = user.round.turn_index
        # binding.pry

        if user.round.highest_bet_for_phase > user.round_bet
            user.make_move("call")
            command = "call"
        else
            user.make_move("check")
            command = "check"
        end
            user = User.find_by(username: "Marley")
            game = user.game

            render json: { message: "Move Success." }
    end

    def get_chips
        chips = @current_user.chips
        render json: { chips: chips }, status: 200
    end

    def add_chips
        user = @current_user
        user.chips += params[:amount]
        user.save
        render json: { chips: user.chips }, status: :accepted
    end

    private

    def user_params
        params.permit(:username, :password, :password_confirmation, :email)
    end
end
