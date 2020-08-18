require 'pry'

class RoomChannel < ApplicationCable::Channel
  def subscribed
    # User has joined is broadcasted in initial fetch.
    stream_from "room_#{params["room"]}"

    rooms = Room.all
  end

  def unsubscribed
    room = Room.find(params["room"])
    user = find_verified_user
    room.users.delete(user)
    user.save

    ActionCable.server.broadcast("room_#{room.id}", { type: "user_has_left" }) 
    ActionCable.server.broadcast("rooms", { type: "user_has_left", room_id: room.id })

    rooms = Room.all
    stop_all_streams
  end
end
