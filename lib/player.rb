# Abstract Class-like
class Player
  def initialize(token)
    @token = token
  end

  def to_s
    @token
  end

  def ==(other)
    return false if !other.is_a?(Player)
    other.to_s == to_s
  end

  ## methods to implement
  # index from minmax functions to take. 0 is min, 1 is max
  def minmax_index ; end
  # default score used in computing a-b search
  def default_v_score ; end
  # play turn in interaction loop
  def play_turn(board, search_depth); end

end

class ComputerPlayer < Player
  def minmax_index
    1
  end

  def default_v_score
    -Float::INFINITY
  end

  def play_turn(board, search_depth)
    # cheat slightly if the board is empty: place a token somewhere random
    return board.mark!(rand(board.size), rand(board.size), self) if board.empty?

    move = board.calculate_move(self, search_depth)
    return false if move[:location].nil?
    board.mark!(move[:location][0], move[:location][1], self)
  end
end

class HumanPlayer < Player
  def minmax_index
    0
  end

  def default_v_score
    Float::INFINITY
  end

  def play_turn(board, search_depth)
    puts board
    puts 'enter move: row,column (zero-indexed)'
    r, c = gets.chomp.split(',').map(&:to_i)
    board.mark!(r, c, self)
  end
end
