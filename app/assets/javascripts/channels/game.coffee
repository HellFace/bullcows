App.game = App.cable.subscriptions.create "GameChannel",
  connected: ->
    $('#step-name').show();

  disconnected: ->

  received: (data) ->
    switch data.action
      when "waiting_opponent"
        $('#register').hide()
        $('#status').html('Waiting for opponent to join')
      when "game_pending"
        $('#register').hide()
        $('#number').show()
        $('#status').html('Your opponent is ' + data.opponent_name + '. Please enter your number for the game...')
      when "waiting_number"
        $('#status').html('Waiting for your opponent to set his number')
      when "game_start"
        $('#status').html("Game is set. We can finally start")
        #App.gamePlay = new Game('#game-container', data.msg)
      when "take_turn"
        $('#status').html("Player found")
        #App.gamePlay.move data.move
        #App.gamePlay.getTurn()
      when "new_game"
        $('#status').html("Player found")
        #App.gamePlay.newGame()
      when "opponent_withdraw"
        $('#status').html("Opponent withdraw, You win!")
        #$('#new-match').removeClass('hidden');
  send_name: (name) ->
    @perform 'set_name', data: name

  send_number: (number) ->
    @perform 'set_number', data: number

  take_turn: (move) ->
    @perform 'take_turn', data: move

  new_game: () ->
    @perform 'new_game'