require 'pry'

class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_#{params["room"]}"

    rooms = Room.all
    ActionCable.server.broadcast("rooms", { type: "current_rooms", rooms: rooms }) 
  end

  def unsubscribed
    room = Room.find(params["room"])
    user = find_verified_user
    room.users.delete(user)
    user.save

    # ActionCable.server.broadcast("room_#{room.id}", { type: "current_room", room: room })
    ActionCable.server.broadcast("room_#{room.id}", { type: "user_has_left" })

    rooms = Room.all
    ActionCable.server.broadcast("rooms", { type: "current_rooms", rooms: rooms })
    stop_all_streams
  end
end
