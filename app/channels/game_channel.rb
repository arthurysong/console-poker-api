require 'pry'

class GameChannel < ApplicationCable::Channel
  def subscribed
    game = Game.find(params["game"])
    stream_from "game_#{game.id}"

    # ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: GameSerializer.new(game).serializable_hash })
    ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
  end

  def unsubscribed
    user = find_verified_user
    game = Game.find(params["game"])

    user.round.player_has_left(user) if user.round && user.round.is_playing#if user is in a round
    
    game.unsit(user)
    user.game_id = nil
    user.reset_user
    user.save

    stop_all_streams

    ActionCable.server.broadcast("game_#{game.id}", { type: "set_game", game: game })
  end
end
