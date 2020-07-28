require 'pry'

class MessagesController < ApplicationController
    def create 
        user = @current_user
        room = user.room
        # binding.pry
        m = Message.create(payload: message_params["message"], user: user, chatbox: room.chatbox)
    
        ActionCable.server.broadcast("room_#{room.id}", {type: "new_message", message: m })

        render json: { success: "Message sent" }, status: 201
    end

    private 

    def message_params
        params.permit(:message)
    end
end
