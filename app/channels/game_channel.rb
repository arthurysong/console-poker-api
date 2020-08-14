require 'pry'

class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_from "game_#{params["game"]}"
  end

  def unsubscribed
    user = find_verified_user
    game = Game.find(params["game"])

    user.round.player_has_left(user) if user.round && user.round.is_playing #if user is in a round
    
    i = game.unsit(user)
    user.game_id = nil
    user.reset_user
    user.save

    ActionCable.server.broadcast("game_#{game.id}", { type: "user_leave", startable: game.startable, seat_index: i })
    stop_all_streams
  end
end
