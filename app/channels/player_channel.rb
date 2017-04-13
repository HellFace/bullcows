class PlayerChannel < ApplicationCable::Channel
  # User has connected
  def subscribed
    stream_from "game_bullcows"
  end

end