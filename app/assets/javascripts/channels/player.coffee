$ ->
  App.player = App.cable.subscriptions.create "PlayerChannel",
    connected: ->
      App.updater = new PlayerUpdater()
      App.updater.init($('#playerData').data('uuid'))

    disconnected: ->
      #App.updater.connectionFailed()

    received: (data) ->
      App.updater.refreshList(data)
