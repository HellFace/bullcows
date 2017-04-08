class GameChannel < ApplicationCable::Channel
  attr_accessor :player
  def subscribed
    stream_from "player_#{uuid}"
    @player = Player.create(uuid: uuid)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    @player.disconnect
  end
  
  def set_name(data)
    @player.update(name: data["data"])
    match_result = @player.set_match
    if match_result == 'waiting_opponent'
      ActionCable.server.broadcast "player_#{uuid}", {action: "waiting_opponent", msg: "Waiting for opponent to connect"}
    else
      ActionCable.server.broadcast "player_#{uuid}", {action: "game_pending", msg: "Start", opponent_name: match_result.name}
      ActionCable.server.broadcast "player_#{match_result.uuid}", {action: "game_pending", msg: "Start", opponent_name: @player.name}
    end
  end
  
  def set_number(data)
    @player.update(number: data[:data])
  end
  
end
