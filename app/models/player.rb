class Player < ApplicationRecord
  attr_accessor :uuid, :name, :number
  
  def initialize(attributes = {})
    @uuid = attributes[:uuid]
  end
  
  def set_name(name)
    @name = name
    
  end
  
  def set_match
    if REDIS.get("waiting").blank?
      REDIS.set("waiting", @uuid)
    else
      opponent = REDIS.get("waiting")
      Game.start(@uuid, opponent)
      REDIS.set("waiting", nil)
    end
  end
  
  def disconnect
    if @uuid == REDIS.get("waiting")
      REDIS.set("waiting", nil)
    end
  end
  
end
