require 'pry'

class MessagesController < ApplicationController
    def create 
        m = Message.create(payload: message_params["message"], user: @current_user, chatbox: @current_user.room.chatbox)
    
        ActionCable.server.broadcast("room_#{@current_user.room.id}", {type: "new_message", message: m })

        render json: { success: "Message sent" }, status: 201
    end

    private 

    def message_params
        params.permit(:message)
    end
end
