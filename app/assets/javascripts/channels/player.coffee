$ ->
  App.player = App.cable.subscriptions.create "PlayerChannel",
    connected: ->
      App.updater = new PlayerUpdater()

    disconnected: ->
      #App.updater.connectionFailed()

    received: (data) ->
      App.updater.refreshList(data)
