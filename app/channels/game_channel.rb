class GameChannel < ApplicationCable::Channel
  attr_accessor :player

  def subscribed
    stream_from "player_#{uuid}"
    @player = Player.create(uuid: uuid)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    @player = Player.find(uuid: uuid).first
    @player.delete
  end
  
  def set_name(data)
    @player.update(name: data["data"])
    match_result = @player.set_match
    if match_result == 'waiting_opponent'
      ActionCable.server.broadcast "player_#{uuid}", {action: "waiting_opponent", msg: "Waiting for opponent to connect"}
    else
      opponent = match_result
      ActionCable.server.broadcast "player_#{uuid}", {action: "game_pending", msg: "Start", opponent_name: opponent.name, whole_op: opponent.opponent}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_pending", msg: "Start", opponent_name: @player.name, status: @player.opponent}
    end
  end
  
  def set_number(data)
    @player = Player.find(uuid: uuid).first
    @player.update(number: data["data"])

    opponent = @player.opponent
    if opponent.number.blank?
      ActionCable.server.broadcast "player_#{uuid}", {action: "waiting_number", msg: "Waiting for opponent to set number"}
    else
      ActionCable.server.broadcast "player_#{uuid}", {action: "game_start", msg: "Start"}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_start", msg: "Start"}
    end
  end
  
end
