class MessagesController < ApplicationController
    def create 
        user = @current_user
        room = user.room
        m = Message.create(payload: message_params["content"], user: user, chatbox: room.chatbox)
    
        ActionCable.server.broadcast("room_#{room.id}", {type: "new_message", message: m })
    end

    private 

    def message_params
        params.permit(:content)
    end
end
