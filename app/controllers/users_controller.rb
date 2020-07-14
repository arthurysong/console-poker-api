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
        game = current_user.game

        if current_user.round
            current_user.make_move(params["command"], params["amount"])

            ActionCable.server.broadcast("game_#{game.id}", { type: "update_round", round: current_user.round })

            render json: { message: "Move Success." }
        else
            render json: { error: "User is not in current round."}
        end
    end

    def get_chips
        chips = current_user.chips
        render json: { chips: chips }, status: 200
    end

    def add_chips
        user = current_user
        user.chips += params[:amount]
        user.save
        render json: { chips: user.chips }, status: :accepted
    end

    private

    def user_params
        params.permit(:username, :password, :password_confirmation, :email)
    end
end
