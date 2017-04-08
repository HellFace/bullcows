class Player < Ohm::Model
  attribute :uuid
  attribute :name
  attribute :number
  attribute :status
  index :status
  reference :opponent, :Player

=begin
  def set_name(name)
    if self.save
      self.name = name
    end
  end

  def set_number(number)
    if self.save
      self.number = number
    end
  end
=end
  
  def set_match
    finder = Player.find(status: 'waiting')
    if finder.empty?
      self.update(status: 'waiting')
      'waiting_opponent'
    else
      waiting = finder.first
      waiting.set_opponent(self)
      set_opponent(waiting)
      return waiting
    end
  end

  def set_waiting
    if self.save
      self.status = 'waiting'
    end
  end

  def set_opponent(player)
    self.update(status: 'playing', opponent: player)
  end
  
  def disconnect
    self.delete
  end
  
end
