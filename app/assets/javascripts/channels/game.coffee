App.game = App.cable.subscriptions.create "GameChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    $('#status').html("You are connected to the server! Please enter your name!")

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    switch data.action
      when "game_pending"
      	#Waiting for player to connect
      
      when "game_start"
        $('#status').html("Player found")
        App.gamePlay = new Game('#game-container', data.msg)

      when "take_turn"
        App.gamePlay.move data.move
        App.gamePlay.getTurn()

      when "new_game"
        App.gamePlay.newGame()

      when "opponent_withdraw"
        $('#status').html("Opponent withdraw, You win!")
        $('#new-match').removeClass('hidden');
        
  send_name: (name) ->
  	@perform 'set_name', data: name
  	
  send_number: (number) ->
  	@perform 'set_number', data: number
  	
  	
  take_turn: (move) ->
    @perform 'take_turn', data: move

  new_game: () ->
    @perform 'new_game'