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
    @player.update(name: data["name"])
    match_result = @player.set_match
    if match_result == 'waiting_opponent'
      ActionCable.server.broadcast "player_#{uuid}", {action: "waiting_opponent"}
    else
      opponent = match_result
      ActionCable.server.broadcast "player_#{uuid}", {action: "game_pending", uuid: uuid, opponent_name: opponent.name}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_pending", uuid: opponent.uuid, opponent_name: @player.name}
    end
  end
  
  def set_number(data)
    @player = Player.find(uuid: uuid).first
    @player.update(number: data["number"])

    opponent = @player.opponent
    if opponent.number.blank?
      ActionCable.server.broadcast "player_#{uuid}", {action: "waiting_number"}
    else
      turn_uuid = [uuid, opponent.uuid].sample
      ActionCable.server.broadcast "player_#{uuid}", {action: "game_start", turn: turn_uuid}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_start", turn: turn_uuid}
    end
  end

  def take_guess(data)
    @player = Player.find(uuid: uuid).first
    opponent = @player.opponent

    result = opponent.check_number(data["guess"])
    response = {action: "take_turn", turn: opponent.uuid, guess: data["guess"], bulls: result[:bulls], cows: result[:cows]}

    ActionCable.server.broadcast "player_#{uuid}", response
    ActionCable.server.broadcast "player_#{opponent.uuid}", response
  end
  
end
