#!/usr/bin/env ruby
require 'byebug'

class Board
  include Enumerable

  def initialize(m) # rows
    raise ArgumentError, 'non-square matrix' if m.map(&:size).uniq.size != 1 || m.map(&:size).uniq.first != m.size
    @m = m
  end

  # alternate constructor for empty board
  def self.empty(arity = 3)
    new((0..arity - 1).map { [nil].cycle(arity) }.map(&:to_a))
  end

  # mark cell on board with some token.
  # mutative. does bounds checking and "is this spot taken" checking
  def mark!(row, col, player)
    return false if invalid_indices(row, col) || !@m[row][col].nil?
    @m[row][col] = player
    true
  end

  # non-mutative version of mark!
  # will fail silently for invalid placements.
  # used in minimax search.
  def mark(row, col, player)
    new_board = Board.new(@m.map(&:dup))
    new_board.mark!(row, col, player)
    new_board
  end

  # enumerable stuff
  def each(&block)
    @m.each(&block)
  end

  def rows(&block)
    @m.each(&block)
  end

  def columns(&block)
    (0..@m.size - 1).map do |i|
      @m.map { |a| a[i] }
    end.each(&block)
  end

  def diagonals(&block)
    # left -> right diagonal + right -> left diagonal
    (
      [(0..max_ind).map { |i| @m[i][i] }] +
      [(0..max_ind).map { |i| @m[max_ind - i][i] }]
    ).each(&block)
  end

  def empty?
    @m.flatten.none?
  end
  # enumerable stuff ends

  # maximum index of board. used for convenience.
  def max_ind
    @m.size - 1
  end

  # does this board have a winner?
  # check if there is a winning row, then if there is a winning column, then diagonal.
  # returns token of the winner
  def winner
    win_rows = rows.select { |r| r.all? && r.uniq.size == 1 }
    return win_rows[0][0] if !win_rows.empty?
    win_cols = columns.select { |c| c.all? && c.uniq.size == 1 }
    return win_cols[0][0] if !win_cols.empty?
    win_diags = diagonals.select { |d| d.all? && d.uniq.size == 1 }
    return win_diags[0][0] if !win_diags.empty?
    nil
  end

  # pretty-print
  def to_s
    rows.reduce('') do |str, r|
      str + '| ' << r.map { |e| e.nil? ? ' ' : e }.join(' | ') + " |\n"
    end
  end

  # returns list of tuples describing non-marked cells
  # -> [ [r,c] ]
  def available_cells
    cells = []
    rows.each_with_index do |row, ri|
      row.each_with_index do |cell, ci|
        cells << [ri, ci] if cell.nil?
      end
    end
    cells
  end

  private

  def invalid_indices(row, col)
    row.nil? || col.nil? || row > max_ind || col > max_ind || row < 0 || col < 0
  end

end

# ## tests todo rspec
# board = Board.new([[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]])
# boardc = Board.new([['X', 'O', nil], ['X', 'O', nil], ['X', nil, nil]])
# boardr = Board.new([['O','O', nil], ['X', 'X', 'X'], [nil, nil, nil]])
# boardd = Board.new([['O','O', nil], ['X', 'O', 'X'], [nil, nil, 'O']])

# puts board.winner
# puts boardc.winner
# puts boardr.winner
# puts boardd.winner
# puts boardc
# ##


# naive minimax search
def calculate_move(board, user_player, computer_player, current_player = computer_player)
  available_cells = board.available_cells

  # base cases
  return { score: -10 } if board.winner == user_player
  return { score: 10 }  if board.winner == computer_player
  return { score: 0 }   if available_cells.empty?


  # the player who is not the current_player
  other_player = current_player == computer_player ? user_player : computer_player

  moves = available_cells.map do |(r, c)|
    {
      location: [r, c],
      score: calculate_move(board.mark(r, c, current_player), user_player, computer_player, other_player)[:score]
    }
  end

  if current_player == computer_player
    moves.max_by { |move| move[:score] }
  else
    moves.min_by { |move| move[:score] }
  end
end
