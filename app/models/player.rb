class Player < Ohm::Model
  attribute :uuid
  attribute :name
  attribute :number
  attribute :status
  index :status
  index :uuid
  reference :opponent, :Player

  def getRandomName
    "Player_" + SecureRandom.urlsafe_base64(5)
  end
  
  def set_match
    finder = Player.find(status: 'waiting')
    if finder.empty?
      if save
        update(status: 'waiting')
      end
      'waiting_opponent'
    else
      waiting = finder.first
      waiting.set_opponent(self)
      set_opponent(waiting)
      return waiting
    end
  end

  def set_opponent(player)
    if save
      update(status: 'playing', opponent: player)
    end
  end

  def check_number(guess)
    bulls = 0
    cows = 0

    player_number = self.number.to_s.chars
    guess.to_s.chars.each_with_index do |value, key|
      if player_number[key] == value
        bulls += 1
      elsif player_number.include?(value) 
        cows += 1
      end
    end

    return {bulls: bulls, cows: cows}
  end

end
