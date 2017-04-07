class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_from "player_#{uuid}"
    player = Player.new(uuid: uuid)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    player.disconnect
  end
  
  def set_name(data)
    player.set_name(data)
    ActionCable.server.broadcast "player_#{uuid}", {action: "game_pending", msg: "Waiting for opponent to connect"}
  end
  
  def set_number(data)
    player.number = data
  end
  
end
