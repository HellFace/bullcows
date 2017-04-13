class GameController < ApplicationController
    def index
        if (session[:uuid].empty?)
            redirect_to controller: "home", action: "index"
        end

        @player = Player.create(uuid: session[:uuid], name: session[:playerName])
    end
end
