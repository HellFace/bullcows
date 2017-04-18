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
    if @player.status == 'playing' && !@player.opponent.nil?
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
      go_home
    end
  end

  def go_home
    ActionCable.server.broadcast "player_#{@uuid}", {action: "game_quit"}
  end


  def go_dashboard(options = {})
    player_uuid = options[:uuid] || @uuid
    message = options[:message] || "Welcome to the BullsCows player dashboard. Enjoy!"
    ActionCable.server.broadcast "player_#{player_uuid}", {action: "go_dashboard", message: message}
  end


  def set_waiting(options = {})
    refresh_player
    @player.update(number: '', opponent: nil, status: 'waiting')

    message = options[:message] || nil

    go_dashboard(message: message)

    broadcast_players
  end


  def send_invite(data)
    ActionCable.server.broadcast "player_#{data["uuid"]}", {action: "receive_invite", uuid: @uuid, name: @player.name}
  end

  def cancel_invite(data)
    go_dashboard(uuid: data["uuid"], message: "The invite has been canceled. Sorry :(")
  end


  def answer_invite(data)
    # start new game
    if data["accept"] == "yes"
      return new_game(data["uuid"])
    end

    # send rejection
    go_dashboard(uuid: data["uuid"], message: "Your invite has been rejected :(")
  end

  def rematch(data)
    new_game(data["uuid"])
  end


  # Start a new game
  # Clear the player's number (but keep their name) and find a new opponent
  def new_game(opponent_uuid)

    refresh_player

    opponent = Player.find(uuid: opponent_uuid).first

    if opponent.nil?
      return go_dashboard(uuid: @uuid, message: "Something went wrong, player not found. Sorry :(")
    end

    # Opponent found - Initiate game as pending
    @player.update(status: 'playing', opponent: opponent, number: nil)
    opponent.update(status: 'playing', opponent: @player, number: nil)

    ActionCable.server.broadcast "player_#{@player.uuid}", {action: "game_pending", opponent_name: opponent.name}
    ActionCable.server.broadcast "player_#{opponent.uuid}", {action: "game_pending", opponent_name: @player.name}

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
      return set_waiting(message: "Your opponent has gone... Sorry")
    end

    # Both players have set their numbers
    unless opponent.number.blank?
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
    Player.all.each do |p|
      if p.status
        players << { uuid: p.uuid, name: p.name, status: p.status }
      end
    end
    ActionCable.server.broadcast "game_bullcows", players
  end
  
end
