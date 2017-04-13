class Player < Ohm::Model
  attribute :uuid
  attribute :name
  attribute :number
  attribute :status
  index :status
  index :uuid
  reference :opponent, :Player


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
