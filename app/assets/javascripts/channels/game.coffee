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
      App.gamePlay.disableInput('Waiting for your opponent to set a number')
      @perform 'set_number', number: number

    take_guess: (guess) ->
      @perform 'take_guess', guess: guess

    rematch: (uuid) ->
      @perform 'rematch', uuid: uuid

    send_invite: (uuid) ->
      @perform 'send_invite', uuid: uuid

    cancel_invite: (uuid) ->
      @perform 'cancel_invite', uuid: uuid

    answer_invite: (data) ->
      @perform 'answer_invite', uuid: data.uuid, accept: data.accept