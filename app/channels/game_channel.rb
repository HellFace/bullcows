class GameChannel < ApplicationCable::Channel
  attr_accessor :player, :uuid
  
  # User has connected - create a player with uuid
  def subscribed
    @uuid = params[:uuid]
    stream_from "player_#{@uuid}"
    refresh_player
  end


  # User has disconnected
  def unsubscribed

    refresh_player
    # Send notification to the opponent if any
    if (@player.status == 'playing')
      ActionCable.server.broadcast "player_#{@player.opponent.uuid}", {action: "game_withdraw"}
    end

    @player.delete
    broadcast_players
  end


  # Get the player directly from Redis
  # Needed after setting the opponents, as it happens on the opponent's side
  def refresh_player
    @player = Player.find(uuid: @uuid).first

    if @player.nil?
      send_error
    end
  end

  def send_error
    ActionCable.server.broadcast "player_#{@uuid}", {action: "game_quit"}
  end


  # Start a new game
  # Clear the player's number (but keep their name) and find a new opponent
  def new_game
    refresh_player
    @player.update(number: '', opponent: nil)

    opponent = Player.find(status: 'waiting').first

    if opponent.nil?
      # No opponent yet - send notification to the player to wait
      @player.update(status: 'waiting')
      ActionCable.server.broadcast "player_#{@uuid}", {action: "waiting_opponent"}
    else
      # Opponent found - Initiate game as pending
      @player.update(status: 'playing', opponent: opponent)
      opponent.update(status: 'playing', opponent: @player)

      ActionCable.server.broadcast "player_#{@player.uuid}", {action: "game_pending", opponent_name: opponent.name}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_pending", opponent_name: @player.name}
    end

    broadcast_players
  end

  
  # Sets the player's number
  # 
  # Params:
  # +data+:: array parameters, containing "number" key
  def set_number(data)
    refresh_player
    @player.update(number: data["number"])

    opponent = @player.opponent

    if opponent.nil?
      return new_game
    end

    if opponent.number.blank?
      # The opponent hasn't set their number yet, send notification to the player to wait
      ActionCable.server.broadcast "player_#{@player.uuid}", {action: "waiting_number"}
    else
      # Both players have set their numbers

      # Choose random player uuid to be first
      turn_uuid = [@player.uuid, opponent.uuid].sample

      ActionCable.server.broadcast "player_#{@player.uuid}", {action: "game_start", turn: turn_uuid}
      ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_start", turn: turn_uuid}
    end
  end

  # Player has sent a guess
  # 
  # Params:
  # +data+:: array parameters, containing "guess" key
  def take_guess(data)
    refresh_player
    opponent = @player.opponent

    # Check the guess against the opponent's number and get the bulls and cows
    result = opponent.check_number(data["guess"])
    response = {action: "take_turn", turn: opponent.uuid, guess: data["guess"], bulls: result[:bulls], cows: result[:cows]}

    # Broadcast the result to thee players
    ActionCable.server.broadcast "player_#{@player.uuid}", response
    ActionCable.server.broadcast "player_#{opponent.uuid}", response
  end
  
  def broadcast_players
    players = []
    Player.all.each { |p| players << { uuid: p.uuid, name: p.name, status: p.status } }
    ActionCable.server.broadcast "game_bullcows", players
  end
  
end
