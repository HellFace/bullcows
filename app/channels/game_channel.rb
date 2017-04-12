class GameChannel < ApplicationCable::Channel
  attr_accessor :player
  
  # User has connected - create a player with uuid
  def subscribed
    stream_from "player_#{uuid}"
    
    if session[:playerName].empty?
      session[:playerName] = Player.getRandomName
    end

    @player = Player.create(uuid: uuid, name: session[:playerName])
  end

  # User has disconnected
  def unsubscribed
    @player = Player.find(uuid: uuid).first

    # Send notification to the opponent if any
    if (@player.status == 'playing')
      ActionCable.server.broadcast "player_#{@player.opponent.uuid}", {action: "game_withdraw"}
    end

    @player.delete
  end
  
  # Sets the player's name
  # 
  # Params:
  # +data+:: array parameters, containing "name" key
  def set_name(data)
    @player.update(name: data["name"])
    match_players
  end

  # Finds an opponent for the player, and initiates the game as pending
  def match_players
    match_result = @player.set_match

    if match_result == 'waiting_opponent'
      # No opponent yet - send notification to the player to wait
      ActionCable.server.broadcast "player_#{uuid}", {action: "waiting_opponent"}
    else
      # Opponent found - Initiate game as pending
      opponent = match_result
      ActionCable.server.broadcast "player_#{uuid}", {action: "game_pending", uuid: uuid, opponent_name: opponent.name}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_pending", uuid: opponent.uuid, opponent_name: @player.name}
    end
  end
  
  # Sets the player's number
  # 
  # Params:
  # +data+:: array parameters, containing "number" key
  def set_number(data)
    @player = Player.find(uuid: uuid).first
    @player.update(number: data["number"])

    opponent = @player.opponent
    if opponent.number.blank?
      # The opponent hasn't set their number yet, send notification to the player to wait
      ActionCable.server.broadcast "player_#{uuid}", {action: "waiting_number"}
    else
      # Both players have set their numbers

      # Choose random player uuid to be first
      turn_uuid = [uuid, opponent.uuid].sample

      ActionCable.server.broadcast "player_#{uuid}", {action: "game_start", turn: turn_uuid}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_start", turn: turn_uuid}
    end
  end

  # Player has sent a guess
  # 
  # Params:
  # +data+:: array parameters, containing "guess" key
  def take_guess(data)
    @player = Player.find(uuid: uuid).first
    opponent = @player.opponent

    # Check the guess against the opponent's number and get the bulls and cows
    result = opponent.check_number(data["guess"])
    response = {action: "take_turn", turn: opponent.uuid, guess: data["guess"], bulls: result[:bulls], cows: result[:cows]}

    # Broadcast the result to thee players
    ActionCable.server.broadcast "player_#{uuid}", response
    ActionCable.server.broadcast "player_#{opponent.uuid}", response
  end

  # Start a new game
  # Clear the player's number (but keep their name) and find a new opponent
  def new_game
    @player = Player.find(uuid: uuid).first
    @player.update(number: '')
    match_players
  end
  
end
