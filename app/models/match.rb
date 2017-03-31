class Match < ApplicationRecord
  
  def self.create(uuid)
    if REDIS.get("waiting").blank?
      REDIS.set("waiting", uuid)
    else
      opponent = REDIS.get("waiting")
      Game.start(uuid, opponent)
      
      REDIS.set("waiting", nil)
    end
  end
  
  def self.remove(uuid)
    if uuid == REDIS.get("waiting")
      REDIS.set("waiting", nil)
    end
  end
  
end
