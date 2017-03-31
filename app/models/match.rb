class Match < ApplicationRecord
  
  def self.create(uuid)
    if REDIS.get("waiting").blank?
      REDIS.set("waiting", uuid)
    else
      opponent = REDIS.get("waiting")
      Game.start(uuid, opponent)
      
      Redis.set("waiting", nil)
    end
  end
  
end
