class PlayerPool < ApplicationRecord
  
  def self.put_player(player)
    
    if REDIS.get("waiting").blank?
      REDIS.set("waiting", @uuid)
    else
      opponent = REDIS.get("waiting")
      Game.start(@uuid, opponent)
      REDIS.set("waiting", nil)
    end
  end
  
  def self.get_player
    
  end
  
  def self.set_opponent(player)
    
  end
  
  def self.get_opponent(player)
    
  end
end
