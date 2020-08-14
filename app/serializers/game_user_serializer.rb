class GameUserSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :username, :chips, :checked, :cards, :current_hand, :dealer, :playing, :round_bet, :winnings, :possible_moves
end