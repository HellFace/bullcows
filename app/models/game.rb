class Game < ApplicationRecord
  def self.start(player1, player2)
    
    ActionCable.server.broadcast "player_#{player1}", {action: "game_start", msg: "Start"}
    ActionCable.server.broadcast "player_#{player2}", {action: "game_start", msg: "Start"}
    
    REDIS.set("opponent_for:#{player1}", player2)
    REDIS.set("opponent_for:#{player2}", player1)
    
  end
end
