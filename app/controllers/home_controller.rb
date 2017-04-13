class HomeController < ApplicationController
    skip_before_action :verify_authenticity_token
  
  def index
  end

  def set_name
    if !params[:name].match(/^[A-Za-z0-9]+$/)
        params[:name] = "Player_" + SecureRandom.urlsafe_base64(5)
    end

    session[:uuid] = SecureRandom.urlsafe_base64
    session[:playerName] = params[:name]
    
    redirect_to controller: "game", action: "index"
  end
  
end
