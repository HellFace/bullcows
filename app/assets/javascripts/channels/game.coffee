App.game = App.cable.subscriptions.create "GameChannel",
  connected: ->
    App.gamePlay = new Game()
    App.gamePlay.init()

  disconnected: ->

  received: (data) ->
    App.gamePlay.dispatchAction(data)

  send_name: (name) ->
    @perform 'set_name', name: name

  send_number: (number) ->
    @perform 'set_number', number: number

  take_guess: (guess) ->
    @perform 'take_guess', guess: guess

  new_game: () ->
    @perform 'new_game'