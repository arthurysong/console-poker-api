require 'pry'

class GameChannel < ApplicationCable::Channel
  def subscribed
    # user = find_verified_user
    game = Game.find(params["game"])
    # game.users << user
    # user.save

    stream_from "game_#{game.id}"

    ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
  end

  def unsubscribed
    user = find_verified_user
    game = Game.find(params["game"])

    #when user joins a game and they haven't played a game 
    if user.round #if user is in a round
      if user.round.is_playing #if user is in a round and is playing..
        user.leave_round
      end
    end
    
    game.users.delete(user)
    user.save


    stop_all_streams

    ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
  end
end
