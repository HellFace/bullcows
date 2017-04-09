class Player < Ohm::Model
  attribute :uuid
  attribute :name
  attribute :number
  attribute :status
  index :status
  index :uuid
  reference :opponent, :Player

  
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

end
