$ ->
  App.game = App.cable.subscriptions.create { channel: "GameChannel", uuid: $('#playerData').data('uuid'), name: $('#playerData').data('name') },
    connected: ->
      App.gamePlay = new Game()
      App.gamePlay.init($('#playerData').data('uuid'))

    disconnected: ->
      App.gamePlay.connectionFailed()

    received: (data) ->
      App.gamePlay.dispatchAction(data)

    set_waiting: () ->
      @perform 'set_waiting'

    send_number: (number) ->
      $('#myNumber').html(number)
      @perform 'set_number', number: number

    take_guess: (guess) ->
      @perform 'take_guess', guess: guess

    new_game: () ->
      @perform 'new_game'

    send_invite: (uuid) ->
      @perform 'send_invite', uuid: uuid

    answer_invite: (uuid, accept) ->
      @perform 'answer_invite', uuid: uuid, accept: accept