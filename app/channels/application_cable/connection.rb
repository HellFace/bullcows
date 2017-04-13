module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :connid
    
    def connect
      self.connid = SecureRandom.urlsafe_base64
    end
    
  end
end
