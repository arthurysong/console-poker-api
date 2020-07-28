require 'pry'

class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_#{params["room"]}"
    user = find_verified_user
    room = Room.find(params["room"])
    room.users << user
    user.save

    ActionCable.server.broadcast("room_#{room.id}", { type: "current_room", room: room })

    rooms = Room.all
    ActionCable.server.broadcast("rooms", { type: "current_rooms", rooms: rooms }) 
  end

  # def create_message(data)
  #   user = find_verified_user
  #   room = user.room
  #   m = Message.create(payload: data["content"], user: user, chatbox: room.chatbox)
    
  #   ActionCable.server.broadcast("room_#{room.id}", {type: "new_message", message: m })
  # end

  def unsubscribed
    room = Room.find(params["room"])
    user = find_verified_user
    room.users.delete(user)
    user.save

    ActionCable.server.broadcast("room_#{room.id}", { type: "current_room", room: room })

    rooms = Room.all
    ActionCable.server.broadcast("rooms", { type: "current_rooms", rooms: rooms })
    stop_all_streams
  end
end
